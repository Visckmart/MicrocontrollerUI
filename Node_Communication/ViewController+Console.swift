//
//  ViewController+Console.swift
//  Node_Communication
//
//  Created by Victor Martins on 16/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

extension ViewController {
    
    /// Uses a 'dumb' check to tell if a command can be run
    ///
    /// The check is simply a match of ```'\r\n> '``` at the end of the console text.
    /// - Returns: whether a command can be run now or not
    func checkIfCanRunCommand() -> Bool {
        let cs = consoleTextStorage.string
        if cs.count > 3 {
            let x = String(cs[cs.index(cs.endIndex, offsetBy: -3)..<cs.endIndex])
            let waitingForCommands = x == "\r\n> "
            print(waitingForCommands ? "Can run" : "Can't run")
            return waitingForCommands
        }
        return true
    }
    
    
    func log(string: String) {
        log(attributedString: NSAttributedString(string: string))
    }
    
    /// Writes a message to the console.
    ///
    /// - Parameters:
    ///   - string: the message content
    ///   - messageType: the message type (common, important)
    func log(string: String, messageType: MessageType) {
        let formattedMessage = Helper.format(asSpecialMessage: string+"\n",
                                             with: messageType)
        self.log(attributedString: formattedMessage)
    }
    
    // TODO: Melhorar
    /// Writes an attributed string to the console.
    ///
    /// - Parameter attributedString: the attributed string to be written
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
            DispatchQueue.main.async {
                self.consoleTextStorage.append(newString)
                let visibleRect = self.consoleTextView.documentVisibleRect
                let bottomOfVisibleRect = visibleRect.origin.y + visibleRect.size.height
                if bottomOfVisibleRect == self.consoleTextView.documentView?.bounds.height {
                    (self.consoleTextView.documentView as! NSTextView).scrollToEndOfDocument(self)
                }
                self.canRunCommand = self.checkIfCanRunCommand()
            }
        }
    }

}
