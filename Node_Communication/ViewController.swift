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
                self.checkFileRefresh()
            }
        }
    }
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
    lazy var dq: Thread = {
        return Thread(target: serial, selector: #selector(serial.incomingTextUpdate(_:)), object: nil)
    }()
    
    func stopReading() {
        dq.cancel()
    }
    
    @IBAction func connectButtonClicked(_ sender: NSButton) {
        if isConnected == false {
            let indexOfSelectedItem = connectionsList.indexOfSelectedItem
            guard indexOfSelectedItem != -1 else {
                print("No item selected")
                return
            }
            print("Will try to connect to \(deviceDiscovery.pathList[indexOfSelectedItem] as? String)")
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
                }
                else { canWrite = true }
                dq.start()
//                dq.add
//                serial.performSelector(inBackground: #selector(serial.incomingTextUpdate(_:)), with: Thread.main)
                
                print("Favorite: \(favoriteDevice ?? "no favorite")")
                favoriteDevice = item
                isConnected = true
            }
        } else {
            print("Would try to disconnect.")
            serial.closeSerialPort()
            dq = Thread(target: serial, selector: #selector(serial.incomingTextUpdate(_:)), object: nil)
        }
    }
    
    // MARK: Writes protocol
    
    var canWrite = false
    func checkIfCanRunCommand() -> Bool {
//        print("Console text: \(consoleTextStorage.string)")
        let regex = try! NSRegularExpression(pattern: "\\n> $", options: [])
        print("Matches: ",regex.matches(in: consoleTextStorage.string, options: [], range: NSRange(location: 0, length: consoleTextStorage.string.count) ))
        return true
    }
    
    func log(string: String) {
        log(attributedString: NSAttributedString(string: string))
    }
    
    func log(attributedString: NSAttributedString) {
        let newString = NSMutableAttributedString(attributedString: attributedString)
        if newString.string.contains("NodeMCU") {
            canWrite = true
            guard let firstIndexOfN = newString.string.firstIndex(of: "N") else {
                return
            }
            let partitionedString = newString.string.suffix(from: firstIndexOfN)
            newString.mutableString.setString(String(partitionedString))
        }
        if canWrite {
            consoleTextStorage.append(newString)
            let visibleRect = consoleTextView.documentVisibleRect
            let bottomOfVisibleRect = visibleRect.origin.y + visibleRect.size.height
            if bottomOfVisibleRect == consoleTextView.documentView?.bounds.height {
                (consoleTextView.documentView as! NSTextView).scrollToEndOfDocument(self)
            }
        }
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
                    self.deviceControl.uploadFile(fileURL)
                    
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
        deviceControl.uploadFile(lastUploadedFile.url)
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

