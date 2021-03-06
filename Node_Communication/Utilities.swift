//
//  Utilities.swift
//  Node_Communication
//
//  Created by Victor Martins on 03/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

func tryCleaningNames(deviceNames: [String]) -> [String] {
    var newNames = [String]()
    for deviceName in deviceNames {
        if deviceName.starts(with: "/dev/cu.") {
            let newStartIndex = deviceName.index(deviceName.startIndex, offsetBy: 8)
            newNames.append(String(deviceName.suffix(from: newStartIndex)))
        } else {
            return deviceNames
        }
    }
    return newNames
}

typealias FilePath = String

func getLastModifiedDate(ofFile file: FilePath) throws -> Date? {
    do {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: file)
        return fileAttributes[.modificationDate] as? Date
    } catch {
        print(error)
        throw error
    }
}

let moveUpSelector = #selector(NSStandardKeyBindingResponding.moveUp(_:))
let moveDownSelector = #selector(NSStandardKeyBindingResponding.moveDown(_:))
