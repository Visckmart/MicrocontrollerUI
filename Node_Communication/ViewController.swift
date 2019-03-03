//
//  ViewController.swift
//  Node_Communication
//
//  Created by Victor Martins on 02/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var sideBar: NSScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    func adaptLayout() {
        sideBar.isHidden = view.frame.width < 500
    }


}

