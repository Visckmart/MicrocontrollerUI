//
//  ViewController+CommandsArea.swift
//  Node_Communication
//
//  Created by Victor Martins on 19/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

// MARK: Commands Area

/** This file extension handles:
 • the send button action
 • the up/down key press events sent (it's used to manipulate the command textfield showing the history of sent commands)
 */
extension ViewController: NSTextFieldDelegate {
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        serial.write(commandTextfield.stringValue)
        commandTextfield.pushHistory()
    }
}
