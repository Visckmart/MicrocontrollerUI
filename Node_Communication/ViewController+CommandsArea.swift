//
//  ViewController+CommandsArea.swift
//  Node_Communication
//
//  Created by Victor Martins on 19/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

extension ViewController {
    
    // MARK: - Commands Area
    
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
            textField == commandTextfield else { return }
        history.updateMostRecentEntry()
    }
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        serial.write(commandTextfield.stringValue)
        commandTextfield.stringValue = ""
        history.pushAndResetPivot()
    }
    
    func altIsPressed(status: Bool) {
        shouldUseAlternativeAction = status
        if status == true && isConnected {
            connectButton.title = "Restart"
        } else {
            connectButton.title = isConnected ? "Close" : "Open"
        }
    }
    
    // TODO: Checar essa parte para ver se realmente está funcionando como deveria
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard control == commandTextfield else { return false }
        
        let direction: CommandHistory.NavigationDirection
        if commandSelector == moveUpSelector        { direction = .back }
        else if commandSelector == moveDownSelector { direction = .forward }
        else { return false }
        
        history.movePivot(to: direction)
        return true
    }
}
