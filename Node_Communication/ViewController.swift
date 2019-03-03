//
//  ViewController.swift
//  Node_Communication
//
//  Created by Victor Martins on 02/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, Writes, NSTextFieldDelegate {
    

    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var connectionsList: NSPopUpButton!
    @IBOutlet weak var connectButton: NSButton!
    
    @IBOutlet weak var consoleTextView: NSScrollView!
    @IBOutlet weak var sideBar: NSScrollView!
    
    @IBOutlet weak var commandTextfield: NSTextField!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var restartCheckbox: NSButton!
    
    private var isConnected: Bool = false
    private var devicesList: [String] = []
    private var consoleTextStorage: NSTextStorage {
        get {
            return (consoleTextView.documentView as! NSTextView).textStorage!
        }
    }
    
    let serial = SerialExample()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        (consoleTextView.documentView as! NSTextView).isEditable = false
        
        serial.interface = self
        serial.prepare()
        refreshList()
        commandTextfield.delegate = self
//        connectButton.keyEquivalent = "\r"
        sendButton.keyEquivalent = "\r"
//        connectButton.becomeFirstResponder()
//        self.view.window?.makeFirstResponder(connectButton)
        restartCheckbox.keyEquivalent = "r"
    }

    
    func tryCleaningNames(deviceNames: [String]) -> [String] {
        var newNames = [String]()
        for deviceName in deviceNames {
            if deviceName.starts(with: "/dev/cu.") {
                let newStartIndex = deviceName.index(deviceName.startIndex, offsetBy: 8)
                newNames.append(String(deviceName.suffix(from: newStartIndex)))
            }
        }
        return newNames
    }
    
    @IBAction func refreshList(_ sender: NSButton? = nil) {
//        print(serial.refreshSerialList())
        connectionsList.removeAllItems()
        if var connectedDevices = serial.refreshSerialList() as? [String] {
            self.devicesList = connectedDevices
            connectedDevices = tryCleaningNames(deviceNames: connectedDevices)
            connectionsList.addItems(withTitles: connectedDevices)
            connectionsList.isEnabled = true
            if let favorite = UserDefaults.standard.string(forKey: "favorite"),
                let positionOfFav = devicesList.firstIndex(of: favorite) {
                connectionsList.selectItem(at: positionOfFav)
            }
            connectButton.isEnabled = true
        } else {
            connectionsList.isEnabled = false
            connectButton.isEnabled = false
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
            print("Will try to connect to \(devicesList[indexOfSelectedItem])")
            let item = devicesList[indexOfSelectedItem]
            print(serial.openSerialPort(item, baud: speed_t(115200)))
            if restartCheckbox.state == .on {
                serial.restart()
            }
//            serial.callSelec()
            serial.performSelector(inBackground: #selector(serial.incomingTextUpdate(_:)), with: Thread.main)
            print("Favorite: \(UserDefaults.standard.string(forKey: "favorite") ?? "no favorite")")
            UserDefaults.standard.set(item, forKey: "favorite")
        } else {
            print("Would try to disconnect.")
//            serial.closeSerialPort()
        }
    }
    
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
    
    func updateConnectionStatus(connected: Bool) {
        print(connected)
        self.isConnected = connected
        if connected {
            connectButton.title = "Close"
        } else {
            connectButton.title = "Open"
        }
    }
    
    var commands: [String] = []
    var historyState = -1 {
        didSet {
            if historyState < -1 {
                historyState = -1
            } else if historyState > commands.count - 1 {
                historyState = commands.count - 1
            }
        }
    }
    @IBAction func sendButtonClicked(_ sender: Any) {
        serial.write(commandTextfield.stringValue)
        commands.insert(commandTextfield.stringValue, at: 0)
        commandTextfield.stringValue = ""
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(commandSelector)
        if commandSelector == #selector(NSStandardKeyBindingResponding.moveUp(_:)) {
            historyState += 1
            if historyState < 0 {
                commandTextfield.stringValue = ""
            } else {
                commandTextfield.stringValue = commands[historyState]
            }
            return true
        } else if commandSelector == #selector(NSStandardKeyBindingResponding.moveDown(_:)) {
            historyState -= 1
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
    
    func adaptLayout() {
        sideBar.isHidden = view.frame.width < 515
        if view.frame.width <= 515 {
            restartCheckbox.title = "Restart"
        } else {
            restartCheckbox.title = "Restart on connection"
        }
    }


}

