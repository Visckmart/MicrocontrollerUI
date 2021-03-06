//
//  CommandHistory.swift
//  Node_Communication
//
//  Created by Victor Martins on 18/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

class CommandHistory {
    
    enum NavigationDirection {
        case back, forward
    }
    
    private var commands: [String] = [""]
    private var historyState: Int = 0 {
        didSet {
            if historyState < -1 {
                NSSound(named: "Funk")?.play()
                historyState = -1
            } else if historyState > commands.count-1 {
                NSSound(named: "Funk")?.play()
                historyState = commands.count-1
            }
        }
    }
    
    @discardableResult
    func push(andResetPivot resetPivot: Bool = true) -> String {
        commands.insert("", at: 0)
        historyState = 0
        return ""
    }
    
    func updateMostRecentEntry(command: String) {
        commands[0] = command
    }
    
    /// Moves the current history state and updates the attatched textfield.
    @discardableResult
    func movePivot(_ dir: NavigationDirection) -> String {
        let currentText = commands[0]
        switch dir {
        case .back:
            // If the history pivot is at -1 and there's something written,
            // the content already went to the position 0. The pivot should
            // indirectly override this position by jumping to the position 1
            let shouldJump = historyState == -1 && !currentText.isEmpty
            if shouldJump { historyState = 1 } else { historyState += 1 }
        case .forward:
            // If the history pivot is at 0 and there's nothing written,
            // it shouldn't go to -1.
            let forwardBlocked = historyState == 0 && currentText.isEmpty
            if !forwardBlocked { historyState -= 1 }
            else { NSSound(named: "Funk")?.play() }
        }
        print("Commands (\(commands.count)): \(commands) | Pivot: \(historyState)")
        
        // If the pivot is at -1 then clear the textfield,
        // else, populate it with the command stored on the history
        if historyState == -1 {
            return ""
        }
        return commands[historyState]
    }
}
