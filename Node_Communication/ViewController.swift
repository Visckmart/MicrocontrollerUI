//
//  ViewController.swift
//  Node_Communication
//
//  Created by Victor Martins on 02/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, Writes {
    
    // MARK: Communication elements
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var connectionsList: NSPopUpButton!
    @IBOutlet weak var connectButton: NSButton!
    
    // MARK: Console and Sidebar
    @IBOutlet weak var consoleTextView: NSScrollView!
    @IBOutlet weak var sideBarWrapper: NSScrollView!

    @IBOutlet weak var uploadButton: NSButton!
    @IBOutlet weak var refreshUploadButton: NSButton!
    @IBOutlet weak var refreshUploadText: NSTextField!
    
    // MARK: Command elements
    @IBOutlet weak var commandTextfield: HistoryTextField!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var restartCheckbox: NSButton!
    
    // MARK: Logic variables
    var isConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                
                self.uploadButton.isEnabled     = self.isConnected
                self.commandTextfield.isEnabled = self.isConnected
                self.sendButton.isEnabled       = self.isConnected
                self.connectButton.title = self.isConnected ? "Close" : "Open"
                if self.isConnected {
                    self.view.window!.makeFirstResponder(self.commandTextfield)
                } else {
                    self.view.window!.makeFirstResponder(self.sendButton)
                }
                self.checkFileRefresh()
            }
        }
    }
    
    // MARK: Convenience variables
    
    private var sideBar: NSOutlineView {
        return sideBarWrapper.documentView as! NSOutlineView
    }
    private var sideBarDataSource: SidebarOutlineView {
        return sideBar.dataSource as! SidebarOutlineView
    }
    
    var consoleTextStorage: NSTextStorage {
        get {
            return (consoleTextView.documentView as! NSTextView).textStorage!
        }
    }
    
    var favoriteDevice: String? {
        get {
            return UserDefaults.standard.string(forKey: "favorite")
        }
        set (newFavorite) {
            if newFavorite != favoriteDevice {
                print("New favorite: \(favoriteDevice ?? "no favorite")")
            }
            UserDefaults.standard.set(newFavorite, forKey: "favorite")
        }
    }
    
    
    /// Indicates if the close button should actually restart the device
    var shouldUseAlternativeAction = false
    
    var files: [String] = [] {
        didSet {
//            print("New files \(files)")
            repopulateSideBar(with: files)
        }
    }
    
    // MARK: -
    
    let history = CommandHistory()
    
    let serial = SerialExample()
    let deviceControl = DeviceIntegration()
    let deviceDiscovery = DeviceDiscovery()
    
    // MARK: - Setup and Layout
    
    override func viewDidLoad() {
        super.viewDidLoad()

        isConnected = false
        deviceControl.serial = serial
        serial.interface = self
        serial.prepare()
        
        setupKeyShortcuts()
        refreshList()
    }
    
    private func setupKeyShortcuts() {
        sendButton.keyEquivalent = "\r"
        
        restartCheckbox.keyEquivalentModifierMask = .command
        restartCheckbox.keyEquivalent = "r"
        
        refreshUploadButton.keyEquivalentModifierMask = [.command, .shift]
        refreshUploadButton.keyEquivalent = "r"
    }
    
    // TODO: Passar essa função para a classe da side bar
    private func repopulateSideBar(with elements: [String]) {
        sideBarDataSource.nomes = elements
        let indexPathsToClear = IndexSet(integersIn: 1..<sideBar.numberOfRows)
        sideBar.removeItems(at: indexPathsToClear, inParent: nil,
                            withAnimation: .effectFade)
        if elements.count >= 1 {
            let indexPathsToInsert = IndexSet(integersIn: 1...elements.count)
            sideBar.insertItems(at: indexPathsToInsert, inParent: nil,
                                withAnimation: .effectFade)
        }
    }
    
    var lastUploadedFile: (url: URL, lastModified: Date)? = nil
    
    func checkFileRefresh() {
        /* TODO: Poderia melhorar se guardasse o arquivo original
         e comparasse com o atual usando Data.isEqual(to other: Data). */
        
        guard let lastUploadedFile = lastUploadedFile else { return }
        let currentModifDate = try? getLastModifiedDate(ofFile: lastUploadedFile.url.path)
        if lastUploadedFile.lastModified < currentModifDate!! {
            refreshUploadButton.isEnabled = true
            
            let filename = lastUploadedFile.url.lastPathComponent
            let uploadText = "Reupload \"\(filename)\" with it's latest changes."
            self.refreshUploadText.stringValue = uploadText
        }
    }
    
    @IBAction func doubleClickOnResultRow(_ sender: Any)
    {
//        print("doubleClickOnResultRow \((sideBarWrapper.documentView as? NSOutlineView)?.clickedRow)")
        if sideBar.clickedRow == 0 {
            deviceControl.readFiles()
        } else {
            deviceControl.runFile(sideBarDataSource.nomes[sideBar.clickedRow-1]+".lua")
        }
        sideBar.deselectRow(sideBar.clickedRow)
    }

    // MARK: - Connection Area
    
    /// Refreshes the list of devices that are connected on the computer.
    @IBAction func refreshList(_ sender: NSButton? = nil) {
        connectionsList.removeAllItems()
        deviceDiscovery.refreshSerialList()
        
        // Grabs the connected devices' paths and names and checks if there's at least one device connected
        if let connectedDevicePaths = deviceDiscovery.pathList as? [String],
           let connectedDeviceNames = deviceDiscovery.nameList as? [String],
            connectedDeviceNames.count > 0 {
            // Add the connected device names to the list on the interface
            connectionsList.addItems(withTitles: connectedDeviceNames)
            // If there's a favorite device and it's on the list, select it
            if let favoriteDevice = favoriteDevice,
               let positionOfFav = connectedDevicePaths.firstIndex(of: favoriteDevice) {
                connectionsList.selectItem(at: positionOfFav)
            }
            
            connectionsList.isEnabled = true
            connectButton.isEnabled = true
        } else {
            connectionsList.isEnabled = false
            connectButton.isEnabled = false
        }
    }
    
    /// Shows an alert in the form of a small window with the appropriate title and icon.
    ///
    /// - Parameter reason: what caused the error, to help the user understand what happened
    func showConnectionErrorAlert(reason: String) {
        let alert = NSAlert()
        alert.messageText = "Não foi possível conectar ao dispositivo."
        alert.informativeText = reason
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.runModal()
    }
    
    /// Tries to connect to the device by opening and setting up the connection.
    ///
    /// - Parameter devicePath: the device to connect
    func connectTo(devicePath: String) {
        // Try to open the port and set up the port
        var openingError: NSError?
        serial.openSerialPort(devicePath, baud: speed_t(115200), didFailWithError: &openingError)
        
        print(openingError ?? "Port openned succesfully")
        guard openingError == nil else { // If there was an error, show an alert
            self.showConnectionErrorAlert(reason: openingError!.localizedDescription)
            return
        }
        
        if restartCheckbox.state == .on {
            deviceControl.restart()
            deviceControl.readFiles()
        } else { canWrite = true }
        
        // The favorite device is now this one
        self.favoriteDevice = devicePath
        
        self.isConnected = true
    }
    
    /// Action called when the open/close/restart button is clicked.
    ///
    /// If not connected, tries to open connection. If connected and the option
    /// key is pressed, restarts the device. Else, closes the connection.
    @IBAction func connectButtonClicked(_ sender: NSButton) {
        // If no device is connected, try to connect to the selected one
        if isConnected == false {
            let indexOfSelectedItem = connectionsList.indexOfSelectedItem
            guard indexOfSelectedItem != -1 else {
                showConnectionErrorAlert(reason: "No item selected.")
                return
            }
            guard let item = deviceDiscovery.pathList[indexOfSelectedItem] as? String else {
                showConnectionErrorAlert(reason: "Item not found on paths' list.")
                return
            }
            print("Will try to connect to \(item)")
            self.connectTo(devicePath: item)
            
        } else { // If there's a connected device
            if shouldUseAlternativeAction { // If the option key is pressed, restart
                print("Will try to restart.")
                deviceControl.restart()
                canWrite = false
            } else { // Else, disconnect
                print("Will try to disconnect.")
                serial.closeSerialPort()
                isConnected = false
            }
        }
    }
    
    /// Updates the open/close connection button to the appropriate behavior.
    ///
    /// The button should behave as a restart button when the connection is
    /// opened and the user is pressing option.
    /// This function is called by the ViewController's window.
    func checkOptionKey() {
        shouldUseAlternativeAction = NSEvent.modifierFlags.contains(.option)
        if shouldUseAlternativeAction && isConnected {
            connectButton.title = "Restart"
        } else {
            connectButton.title = isConnected ? "Close" : "Open"
        }
    }
    
    @objc var canRunCommand = false {
        didSet {
            serial.setWriteAvailability(canRunCommand)
            print("canRunCommand \(canRunCommand)")
        }
    }
    
    // MARK: Writes protocol
    
    var canWrite = false

}

