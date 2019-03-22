//
//  CommandHistoryTests.swift
//  Node_CommunicationTests
//
//  Created by Victor Martins on 20/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import XCTest
@testable import Node_Communication

class CommandHistoryTests: XCTestCase {

    var history: CommandHistory!
    
    override func setUp() {
        history = CommandHistory()
    }
    
    func testWriteCommandAndGoBackToIt() {
        let firstCommand = "Command"
        history.updateMostRecentEntry(command: firstCommand)
        history.push()
        
        XCTAssertEqual(history.movePivot(.back), firstCommand,
                       "History not saving commands")
    }
    
    func testWriteCommandThenGoBackAndForth() {
        let firstCommand = "Command A"
        history.updateMostRecentEntry(command: firstCommand)
        history.push()
        
        let secondCommand = "Command B"
        history.updateMostRecentEntry(command: secondCommand)
        
        history.movePivot(.back)
        XCTAssertEqual(history.movePivot(.forward), secondCommand,
                       "History not navigating correctly")
    }
    
    func testHistoryBackLimit() {
        let firstCommand = "Command Back"
        history.updateMostRecentEntry(command: firstCommand)
        history.push()
        
        history.movePivot(.back)
        
        let originalCommand = history.movePivot(.back)
        let limitedOriginalCommand = history.movePivot(.back)
        
        XCTAssertEqual(originalCommand, limitedOriginalCommand,
                       "History is acting improperly when trying to go past the first command sent.")
    }
    
    func testHistoryForwardClear() {
        let command = "Command Forward Clear"
        history.updateMostRecentEntry(command: command)
        history.push()
        
        history.movePivot(.back)
        history.movePivot(.forward)
        XCTAssertEqual(history.movePivot(.forward), "",
                       "History not clearing input when moving pivot to position -1.")
    }
    
    func testHistoryForwardLimit() {
        let command = "Command Forward Limit"
        history.updateMostRecentEntry(command: command)
        history.push()
        
        let placeholder = "Command placeholder"
        history.updateMostRecentEntry(command: placeholder)
        
        history.movePivot(.forward)
        let currentCommand = history.movePivot(.forward)
        XCTAssertEqual(currentCommand, "",
                       "History is acting improperly when trying to move the pivot to position -1.")
        
        XCTAssertEqual(history.movePivot(.back), command,
                       "History pivot seems to be going beyond -1.")
    }
    
    func testHistoryJump() {
        let jumpCommand = "Jump command"
        history.updateMostRecentEntry(command: jumpCommand)
        history.push()
        
        let newCommand = "New command"
        history.updateMostRecentEntry(command: newCommand)
        
        history.movePivot(.forward)
        
        let newestCommand = "Newest command"
        history.updateMostRecentEntry(command: newestCommand)
        
        let jumpResult = history.movePivot(.back)
        XCTAssertEqual(jumpResult, jumpCommand, "Jump not happening correctly.")
        
        let backFromJumpResult = history.movePivot(.forward)
        XCTAssertEqual(backFromJumpResult, newestCommand, "Jump not happening correctly, but the problem might not be in the jump code itself.")
    }
    
    func testGeneralBehavior() {
        var previousCommand, currentCommand: String
        var firstCommand = "Command o"
        history.updateMostRecentEntry(command: firstCommand)
        firstCommand = "Command one"
        history.updateMostRecentEntry(command: firstCommand)
        history.push()
        
        let secondCommand = "Command two"
        history.updateMostRecentEntry(command: secondCommand)
        history.push()
        
        history.movePivot(.back)
        previousCommand = history.movePivot(.back)
        XCTAssertEqual(previousCommand, firstCommand)
        
        currentCommand = history.movePivot(.forward)
        XCTAssertEqual(currentCommand, secondCommand)
        history.movePivot(.forward)
        
        let thirdCommand = "Command three"
        history.updateMostRecentEntry(command: thirdCommand)
        
        previousCommand = history.movePivot(.back)
        XCTAssertEqual(previousCommand, secondCommand)
        
        currentCommand = history.movePivot(.forward)
        XCTAssertEqual(currentCommand, thirdCommand)
        
        history.movePivot(.forward)
        let fourthCommand = "Command four"
        history.updateMostRecentEntry(command: fourthCommand)
        
        previousCommand = history.movePivot(.back)
        XCTAssertEqual(previousCommand, secondCommand)
        
        currentCommand = history.movePivot(.forward)
        XCTAssertEqual(currentCommand, fourthCommand)
        
        currentCommand = history.push()
        XCTAssertEqual(currentCommand, "")
    }
    
    override func tearDown() {
        history = nil
    }
}
