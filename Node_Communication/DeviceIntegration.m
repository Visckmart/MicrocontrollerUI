//
//  DeviceIntegration.m
//  Node_Communication
//
//  Created by Victor Martins on 13/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceIntegration.h"

@implementation DeviceIntegration : NSObject

/**
 Restarts the connected device.
 */
- (void) restart {
    [self.serial writeString:@"node.restart()"];
}

/**
 Runs a file on the connected device using 'dofile(filename)'.
 
 @param fileName The full name of the file to be run.
 (Not a path because there's no such thing on the device)
 */
- (void) runFile: (NSString *) fileName {
    NSString * message = [NSString stringWithFormat:@"Running \"%@\"", fileName];
    NSString * command = [NSString stringWithFormat:@"dofile(\"%@\")", fileName];
    [self.serial runCommand:command withIdentifier:common andMessage:message withMessageType:MessageType_Common];
}

/**
 Runs the command to refresh the files' list.
 When the response is complete, the incomingTextUpdateThread will
 update the UI properly.
 */
- (void) readFiles {
    NSString * command = @"for name in pairs(file.list()) do print(name) end";
    [self.serial runCommand:command withIdentifier:readingFiles andMessage:@"Update files list" withMessageType:MessageType_Common];
}

typedef NSString Program;

/**
 Uploads a file from the computer to the connected device.
 
 @param filePath The full path of the file on the computer.
 */
- (void) uploadFile:(NSURL *)filePath {
    NSData * file = [NSData dataWithContentsOfURL:filePath];
    if (file == nil) { // If couldn't read the file
        NSLog(@"Upload aborted because the file couldn't be loaded.");
        return;
    }
    
    // Prepare the dictionary that will be used to customize the upload program
    NSNumber * dataSize = @([file length] + 2);
    NSDictionary * dict = [NSDictionary dictionaryWithObjects: @[filePath.lastPathComponent, dataSize.stringValue] forKeys: @[@"filename", @"filesize"]];
    
    // Load and customize properly the upload program
    Program * prepareFileUpload = [self.serial prepareProgram:@"FileUpload_Start" withData:dict];
    NSLog(@"\n--File--\n%@\n--------", prepareFileUpload);
    if (prepareFileUpload == NULL) { // If the program couldn't be loaded
        NSLog(@"Upload aborted because it couldn't be prepared.");
        return;
    }
    
    // Load the contents of the file onto a NSString
    NSString * fileContent = [[NSString alloc] initWithData: file encoding: NSUTF8StringEncoding];
    
    // Effectively uploads the file
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.serial writeString: prepareFileUpload];
        [self.serial writeString: fileContent];
    });
}
@end
