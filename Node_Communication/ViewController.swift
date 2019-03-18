//
//  ViewController.swift
//  Node_Communication
//
//  Created by Victor Martins on 02/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, Writes, NSTextFieldDelegate {
    
    // MARK: Communication elements
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var connectionsList: NSPopUpButton!
    @IBOutlet weak var connectButton: NSButton!
    
    // MARK: Console and Sidebar
    @IBOutlet weak var consoleTextView: NSScrollView!
    @IBOutlet weak var sideBarWrapper: NSScrollView!
    private var sideBar: NSOutlineView {
        return sideBarWrapper.documentView as! NSOutlineView
    }
    
    @IBOutlet weak var uploadButton: NSButton!
    @IBOutlet weak var refreshUploadButton: NSButton!
    @IBOutlet weak var refreshUploadText: NSTextField!
    
    // MARK: Command elements
    @IBOutlet weak var commandTextfield: NSTextField!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var restartCheckbox: NSButton!
    
    // MARK: Logic variables
    
    var isConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                let connectionState = self.isConnected
                
                self.uploadButton.isEnabled = connectionState
                self.commandTextfield.isEnabled = connectionState
                self.sendButton.isEnabled = connectionState
                self.connectButton.title = connectionState ? "Close" : "Open"
                self.checkFileRefresh()
                self.view.window!.makeFirstResponder(connectionState ?self.commandTextfield : self.sendButton)
            }
        }
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
            UserDefaults.standard.set(newFavorite, forKey: "favorite")
        }
    }
    
    var shouldUseAlternativeAction = false
    
    var files: [String] = [] {
        didSet {
//            print("New files \(files)")
            repopulateSideBar(with: files)
        }
    }
    
    let history = CommandHistory()
    
    let serial = SerialExample()
    let deviceControl = DeviceIntegration()
    let deviceDiscovery = DeviceDiscovery()
    
    // MARK: - Setup e Layout
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        (consoleTextView.documentView as! NSTextView).isEditable = false
        isConnected = false
        deviceControl.serial = serial
        serial.interface = self
        serial.prepare()
        refreshList()
        commandTextfield.delegate = self
        sendButton.keyEquivalent = "\r"
        restartCheckbox.keyEquivalent = "r"
        sideBar.doubleAction = #selector(ViewController.doubleClickOnResultRow)
        history.attatchedTextField = commandTextfield
    }
    
    // TODO: Passar essa função para a classe da side bar
    private func repopulateSideBar(with elements: [String]) {
        (sideBar.dataSource as! SidebarOutlineView).nomes = elements
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
            self.refreshUploadText.stringValue = "Reupload \"\(lastUploadedFile.url.lastPathComponent)\" with it's latest changes."
        }
    }
    
    @objc func doubleClickOnResultRow()
    {
//        print("doubleClickOnResultRow \((sideBarWrapper.documentView as? NSOutlineView)?.clickedRow)")
        if sideBar.clickedRow == 0 {
            deviceControl.readFiles()
        } else {
            deviceControl.runFile((sideBar.dataSource as! SidebarOutlineView).nomes[sideBar.clickedRow-1])
        }
        sideBar.deselectRow(sideBar.clickedRow)
    }
    
    func adaptLayout() {
        sideBarWrapper.isHidden = view.frame.width < 515
        if view.frame.width <= 515 {
            restartCheckbox.title = "Restart"
        } else {
            restartCheckbox.title = "Restart and refresh files on connection"
        }
    }

    // MARK: - Connection Area
    
    @IBAction func refreshList(_ sender: NSButton? = nil) {
        connectionsList.removeAllItems()
        deviceDiscovery.refreshSerialList()
        if let connectedDevicePaths = deviceDiscovery.pathList as? [String],
           let connectedDeviceNames = deviceDiscovery.nameList as? [String] {
            connectionsList.addItems(withTitles: connectedDeviceNames)
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
    
    @IBAction func serialListAction(_ sender: Any) {
//        print(connectionsList.selectedItem?.title)
    }
    
    @IBAction func connectButtonClicked(_ sender: NSButton) {
        if isConnected == false {
            let indexOfSelectedItem = connectionsList.indexOfSelectedItem
            guard indexOfSelectedItem != -1 else {
                print("No item selected")
                return
            }
            print("Will try to connect to \(deviceDiscovery.pathList[indexOfSelectedItem] as! String)")
            let item = deviceDiscovery.pathList[indexOfSelectedItem] as! String
            let openingResponse = serial.openSerialPort(item, baud: speed_t(115200))
            if openingResponse != nil {
                let alert = NSAlert()
                alert.messageText = "Não foi possível conectar ao dispositivo."
                alert.informativeText = openingResponse!
                alert.icon = NSImage(named: NSImage.cautionName)
                alert.runModal()
            } else {
                if restartCheckbox.state == .on {
                    deviceControl.restart()
                    deviceControl.readFiles()
//                    serial.write("node.restart()")
//                    serial.runCommand("node.restart()", withIdentifier: .none)
                }
                else { canWrite = true }
                
                print("Favorite: \(favoriteDevice ?? "no favorite")")
                favoriteDevice = item
                isConnected = true
//                commandTextfield.isEnabled = false
//                commandTextfield.isEnabled = true
//                commandTextfield.window!.makeFirstResponder(commandTextfield)
//                sender.resignFirstResponder()
            }
        } else {
            if shouldUseAlternativeAction {
                print("Would try to restart.")
                deviceControl.restart()
            } else {
                print("Would try to disconnect.")
                serial.closeSerialPort()
                isConnected = false
            }
        }
    }
    
    @objc dynamic var canRunCommand = false {
        didSet {
            serial.setWriteAvailability(canRunCommand)
            print("canRunCommand \(canRunCommand)")
        }
    }
    
    // MARK: Writes protocol
    
    var canWrite = false
    
    func uploadProcedure(fileURL: URL) {
        print("Panel URL: \(String(describing: fileURL))")
        self.serial.write("print('Will upload file \(fileURL.lastPathComponent)')")
        self.deviceControl.uploadFile(fileURL)
        
        // TODO: Improve with Swift 5
        if let lastModif = try? getLastModifiedDate(ofFile: fileURL.path) {
            self.lastUploadedFile = (url: fileURL, lastModified: lastModif!)
            self.refreshUploadText.stringValue = "This button allows you to reupload the most recent file if changes were made."
        }
    }
    
    @IBAction func uploadButtonClicked(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.begin { (response) in
            if response == .OK, let chosenFileURL = panel.url {
                self.uploadProcedure(fileURL: chosenFileURL)
            } else if response == NSApplication.ModalResponse.cancel {
                print("cancelled")
            }
        }
    }
    
    @IBAction func refreshLastUpload(_ sender: Any) {
        guard let lastUploadedFile = lastUploadedFile else {
            print("Não deveria poder dar refresh")
            return
        }
//        self.serial.write("print('Will reupload file \(lastUploadedFile.url)')")
        deviceControl.uploadFile(lastUploadedFile.url)
        if let lastModif = try? getLastModifiedDate(ofFile: lastUploadedFile.url.path) {
            self.lastUploadedFile!.lastModified = lastModif!
        }
        refreshUploadButton.isEnabled = false
    }
    
    // MARK: - Commands Area
    
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
            textField == commandTextfield else { return }
        history.updateMostRecentEntry()
    }
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        serial.write(commandTextfield.stringValue)
        commandTextfield.stringValue = ""
        history.pushAndResetPivot()
    }
    
    func altIsPressed(status: Bool) {
        shouldUseAlternativeAction = status
        if status == true && isConnected {
            connectButton.title = "Restart"
        } else {
            connectButton.title = isConnected ? "Close" : "Open"
        }
    }
    
    // TODO: Checar essa parte para ver se realmente está funcionando como deveria
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard control == commandTextfield else { return false }
        
        let direction: CommandHistory.NavigationDirection
        if commandSelector == moveUpSelector        { direction = .back }
        else if commandSelector == moveDownSelector { direction = .forward }
        else { return false }
        
        history.movePivot(to: direction)
        return true
    }


}

