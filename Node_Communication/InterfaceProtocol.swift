//
//  InterfaceProtocol.swift
//  Node_Communication
//
//  Created by Victor Martins on 03/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

@objc protocol Writes {
    func log(string: String)
    func log(attributedString: NSAttributedString)
    func updateConnectionStatus(connected: Bool)
    var files: [String] { get set }
}
