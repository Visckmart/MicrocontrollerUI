//
//  ViewController+Console.swift
//  Node_Communication
//
//  Created by Victor Martins on 16/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

extension ViewController {
    
    func checkIfCanRunCommand() -> Bool {
        //        print("Console text: \(consoleTextStorage.string)")
//        let regex = try! NSRegularExpression(pattern: "\r\n> ", options: [])
        let cs = consoleTextStorage.string
        if cs.count > 3 {
            let x = String(cs[cs.index(cs.endIndex, offsetBy: -3)..<cs.endIndex])
//        print("Matches: ",regex.matches(in: x, options: [.withTransparentBounds], range: NSRange(location: 0, length: x.count) ))
            print(x == "\r\n> " ? "Can run" : "Can't run")
            return x == "\r\n> "
        }
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
