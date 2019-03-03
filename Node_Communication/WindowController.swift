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
//        if window!.frame.width < CGFloat(500) {
//            print("small")
            (contentViewController as! ViewController).adaptLayout()
//        } else {
//            print("big")
//        }
    }

}
