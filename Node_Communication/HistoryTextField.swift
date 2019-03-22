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
}
