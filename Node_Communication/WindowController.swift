//
//  WindowController.swift
//  Node_Communication
//
//  Created by Victor Martins on 03/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {

    var viewController: ViewController {
        return (contentViewController as! ViewController)
    }
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    override var acceptsFirstResponder: Bool { return true }
    override func flagsChanged(with event: NSEvent) {
//        print(event)
        let optionPressed = NSEvent.modifierFlags.contains(.option)
        viewController.altIsPressed(status: optionPressed)
    }
    
    func windowDidResize(_ notification: Notification) {
        (contentViewController as! ViewController).adaptLayout()
    }
    func windowDidBecomeMain(_ notification: Notification) {
//        print(#function)
        let optionPressed = NSEvent.modifierFlags.contains(.option)
        viewController.altIsPressed(status: optionPressed)
        viewController.checkFileRefresh()
    }

}
