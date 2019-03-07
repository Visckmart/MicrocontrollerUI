//
//  SidebarOutlineView.swift
//  Node_Communication
//
//  Created by Victor Martins on 03/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class SidebarOutlineView: NSOutlineView, NSOutlineViewDataSource, NSOutlineViewDelegate {

    var nomes: [String] = []
    let dataCellID = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
    let refreshCellID = NSUserInterfaceItemIdentifier(rawValue: "RefreshCell")
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return nomes.count + 1
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            if index == 0 { return "Refresh" }
            return nomes[index-1]
        }
        fatalError()
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if (item as! String) == "Refresh" {
            return 24
        }
        return 20
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return item
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? String else {
            fatalError("Source view item isn't a label.")
        }
        let cellID: NSUserInterfaceItemIdentifier
        
        if item == "Refresh" {
            cellID = refreshCellID
        } else {
            cellID = dataCellID
        }
        
        let view = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
        
        if let textField = view?.textField {
            textField.stringValue = item
            textField.sizeToFit()
        }
        return view
    }
    
}
