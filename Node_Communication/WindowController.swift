//
//  WindowController.swift
//  Node_Communication
//
//  Created by Victor Martins on 03/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {

    // Convenience variable to refer to the ViewController that's inside the window
    var viewController: ViewController {
        return (contentViewController as! ViewController)
    }
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func flagsChanged(with event: NSEvent) {
        viewController.checkOptionKey()
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        viewController.checkOptionKey()
        viewController.checkFileRefresh()
    }

}
