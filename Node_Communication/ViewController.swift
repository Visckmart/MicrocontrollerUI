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
    
    private var isConnected: Bool = false
    private var rawDeviceNames: [String] = []
    private var consoleTextStorage: NSTextStorage {
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
    
    var files: [String] = [] {
        didSet {
//            print("New files \(files)")
            repopulateSideBar(with: files)
        }
    }
    
    let serial = SerialExample()
    
    // MARK: - Setup e Layout
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        (consoleTextView.documentView as! NSTextView).isEditable = false
        
        serial.interface = self
        serial.prepare()
        refreshList()
        commandTextfield.delegate = self
        sendButton.keyEquivalent = "\r"
        restartCheckbox.keyEquivalent = "r"
        sideBar.doubleAction = #selector(ViewController.doubleClickOnResultRow)
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
//        print("Checking \(lastUploadedFile.path)");
        let currentModifDate = try? getLastModifiedDate(ofFile: lastUploadedFile.url.path)
        print(lastUploadedFile.lastModified, currentModifDate as Any)
        if lastUploadedFile.lastModified < currentModifDate!! {
            refreshUploadButton.isEnabled = true
            self.refreshUploadText.stringValue = "Reupload \"\(lastUploadedFile.url.lastPathComponent)\" with it's latest changes."
        }
    }
    
    @objc func doubleClickOnResultRow()
    {
//        print("doubleClickOnResultRow \((sideBarWrapper.documentView as? NSOutlineView)?.clickedRow)")
        if sideBar.clickedRow == 0 {
            serial.readFiles()
        } else {
            serial.runFile((sideBar.dataSource as! SidebarOutlineView).nomes[sideBar.clickedRow-1])
        }
        sideBar.deselectRow(sideBar.clickedRow)
    }
    
    func adaptLayout() {
        sideBarWrapper.isHidden = view.frame.width < 515
        if view.frame.width <= 515 {
            restartCheckbox.title = "Restart"
        } else {
            restartCheckbox.title = "Restart on connection"
        }
    }

    // MARK: - Connection Area
    
    @IBAction func refreshList(_ sender: NSButton? = nil) {
        connectionsList.removeAllItems()
        if let connectedDevices = serial.refreshSerialList() as? [String] {
            self.rawDeviceNames = connectedDevices
            connectionsList.addItems(withTitles: tryCleaningNames(deviceNames: connectedDevices))
            connectionsList.isEnabled = true
            if let favoriteDevice = favoriteDevice,
                let positionOfFav = rawDeviceNames.firstIndex(of: favoriteDevice) {
                connectionsList.selectItem(at: positionOfFav)
            }
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
            print("Will try to connect to \(rawDeviceNames[indexOfSelectedItem])")
            let item = rawDeviceNames[indexOfSelectedItem]
            print(serial.openSerialPort(item, baud: speed_t(115200)))
            if restartCheckbox.state == .on { serial.restart() }
            else { canWrite = true }
            serial.performSelector(inBackground: #selector(serial.incomingTextUpdate(_:)), with: Thread.main)
            
            print("Favorite: \(favoriteDevice ?? "no favorite")")
            favoriteDevice = item
        } else {
            print("Would try to disconnect.")
//            serial.closeSerialPort()
        }
    }
    
    // MARK: Writes protocol
    
    var canWrite = false
    
    func log(string: String) {
//        print("Write called")
        
        var newString = string
        if string.contains("NodeMCU") {
            canWrite = true
            newString = String(newString.suffix(from: newString.firstIndex(of: "N")!))
        }
        if canWrite {
            consoleTextStorage.append(NSAttributedString(string: newString))
            (consoleTextView.documentView as! NSTextView).scrollToEndOfDocument(self)
        }
    }
    
    func log(attributedString: NSAttributedString) {
        consoleTextStorage.append(attributedString)
        (consoleTextView.documentView as! NSTextView).scrollToEndOfDocument(self)
    }
    
    func updateConnectionStatus(connected: Bool) {
        self.isConnected = connected
        if connected {
            connectButton.title = "Close"
        } else {
            connectButton.title = "Open"
        }
    }
    
    @IBAction func uploadButtonClicked(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.begin { (response) in
            if response == .OK {
                print("Panel URL: \(String(describing: panel.url))")
                if let fileURL = panel.url {
//                    self.serial.write("print('Would upload file \(fileURL.lastPathComponent)')")
                    self.serial.uploadFile(fileURL)
                    
                    // TODO: Improve with Swift 5
                    if let lastModif = try? getLastModifiedDate(ofFile: fileURL.path) {
                        self.lastUploadedFile = (url: fileURL, lastModified: lastModif!)
                        self.refreshUploadText.stringValue = "This button allows you to reupload the most recent file if changes were made."
                    }
                }
            } else if response == NSApplication.ModalResponse.cancel {
                print("cancelled")
            }
        }
//        serial.uploadFile(URL(fileURLWithPath: "abcd"))
    }
    
    @IBAction func refreshLastUpload(_ sender: Any) {
        guard let lastUploadedFile = lastUploadedFile else {
            print("Não deveria poder dar refresh")
            return
        }
//        self.serial.write("print('Will reupload file \(lastUploadedFile.url)')")
        self.serial.uploadFile(lastUploadedFile.url)
        if let lastModif = try? getLastModifiedDate(ofFile: lastUploadedFile.url.path) {
            self.lastUploadedFile!.lastModified = lastModif!
        }
        refreshUploadButton.isEnabled = false
    }
    
    // MARK: - Commands Area
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        serial.write(commandTextfield.stringValue)
        commands.insert(commandTextfield.stringValue, at: 0)
        commandTextfield.stringValue = ""
        historyState = -1
    }
    
    var commands: [String] = []
    var historyState = -1 {
        didSet {
            if historyState < -1 {
                historyState = -1
            } else if historyState > commands.count - 1 {
                historyState = commands.count - 1
            }
//            switch historyState {
//            case ..<(-1):
//                historyState = -1
//            case commands.count...:
//                historyState = commands.count - 1
//            default: break
//            }
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//        print(commandSelector)
        // Se o comando foi seta pra cima ou pra baixo
        if commandSelector == moveUpSelector || commandSelector == moveDownSelector {
            switch commandSelector {
            case moveUpSelector:    historyState += 1
            case moveDownSelector:  historyState -= 1
            default: return false
            }
            if historyState < 0 {
                commandTextfield.stringValue = ""
            } else {
                commandTextfield.stringValue = commands[historyState]
            }
            return true
        } else {
            return false
        }
    }


}

