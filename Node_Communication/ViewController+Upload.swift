//
//  ViewController+Upload.swift
//  Node_Communication
//
//  Created by Victor Martins on 06/04/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

import Foundation

extension ViewController {
    
    @IBAction func uploadButtonClicked(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.begin { (response) in
            if response == .OK, let chosenFileURL = panel.url {
                print("Panel URL: \(chosenFileURL.absoluteString)")
                self.uploadFileProcedure(fileURL: chosenFileURL)
            } else if response == NSApplication.ModalResponse.cancel {
                print("Cancelled")
            }
        }
    }
    
    func uploadFileProcedure(fileURL: URL) {
        self.log(string: "Uploading \(fileURL.lastPathComponent)", messageType: .common)
        self.deviceControl.uploadFile(fileURL)
        
        // TODO: Improve with Swift 5
        if let lastModif = try? getLastModifiedDate(ofFile: fileURL.path) {
            self.lastUploadedFile = (url: fileURL, lastModified: lastModif!)
            self.refreshUploadText.stringValue = "This button allows you to reupload the most recent file if changes were made."
        }
    }
    
    @IBAction func refreshLastUpload(_ sender: Any) {
        guard let lastUploadedFile = lastUploadedFile else {
            print("Não deveria poder dar refresh.")
            return
        }
        
        self.log(string: "Reuploading \(lastUploadedFile.url.lastPathComponent)", messageType: .common)
        deviceControl.uploadFile(lastUploadedFile.url)
        if let lastModif = try? getLastModifiedDate(ofFile: lastUploadedFile.url.path) {
            self.lastUploadedFile!.lastModified = lastModif!
        }
        refreshUploadButton.isEnabled = false
    }
}
