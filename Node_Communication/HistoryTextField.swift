//
//  HistoryTextField.swift
//  Node_Communication
//
//  Created by Victor Martins on 21/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

class HistoryTextField: NSTextField, NSTextFieldDelegate {
    
    private var history = CommandHistory()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.delegate = self
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.delegate = self
    }
    
    func pushHistory() {
        self.stringValue = history.push()
    }
    
    func movePivot(_ dir: CommandHistory.NavigationDirection) {
        self.stringValue = history.movePivot(dir)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        history.updateMostRecentEntry(command: self.stringValue)
    }
    
    // TODO: Checar essa parte para ver se realmente está funcionando como deveria
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // If the target isn't the command textfield, do nothing
//        guard control == commandTextfield else { return false }
        
        let direction: CommandHistory.NavigationDirection
        
        switch commandSelector {
        // If the user pressed the up key, it wants to go back in the history
        case moveUpSelector: direction = .back
        // If the user pressed the down key, it wants to go forward
        case moveDownSelector: direction = .forward
        // If none of these keys were pressed, do nothing
        default: return false
        }
        
        // Moves the history pivot accordingly
        self.movePivot(direction)
        return true
    }
}
