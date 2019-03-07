//
//  WindowController.swift
//  Node_Communication
//
//  Created by Victor Martins on 03/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func windowDidResize(_ notification: Notification) {
            (contentViewController as! ViewController).adaptLayout()
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
//        print(#function)
        (contentViewController as! ViewController).checkFileRefresh()
    }

}
