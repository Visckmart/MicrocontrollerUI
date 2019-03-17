//
//  DeviceIntegration.h
//  Node_Communication
//
//  Created by Victor Martins on 13/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SerialExample.h"

#ifndef DeviceIntegration_h
#define DeviceIntegration_h

/**
 This class handles the proccess of sending *common commands* to the connected device.
 */
@interface DeviceIntegration : NSObject
@property (weak) SerialExample * serial;

- (void) runFile: (NSString *) fileName;
- (void) readFiles;
- (void) restart;
- (void) uploadFile:(NSURL *)filePath;
@end


#endif /* DeviceIntegration_h */
