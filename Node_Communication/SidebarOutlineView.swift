//
//  SidebarOutlineView.swift
//  Node_Communication
//
//  Created by Victor Martins on 03/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Cocoa

class SidebarOutlineView: NSOutlineView, NSOutlineViewDataSource, NSOutlineViewDelegate {

    let nomes = ["A", "Teste", "B", "C"]
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            print("first item")
            return nomes.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return nomes[index]
        }
        fatalError()
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        print(item)
        return item
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView
        view?.frame.size.width = outlineView.frame.width
        if let textField = view?.textField {
            //3
            textField.stringValue = item as! String
            textField.sizeToFit()
        }
        return view
    }
    
}
