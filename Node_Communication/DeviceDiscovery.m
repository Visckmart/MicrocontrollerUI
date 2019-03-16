//
//  DeviceDiscovery.m
//  Node_Communication
//
//  Created by Victor Martins on 13/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>

@interface DeviceDiscovery : NSObject
- (NSString *) pathForName:(NSString *) name;
- (void) refreshSerialList;
@property NSMutableArray<NSString *> * nameList;
@property NSMutableArray<NSString *> * pathList;
@end

//@interface DeviceDiscovery(Private)
//@property NSMutableArray<NSString *> * nameList;
//@property NSMutableArray<NSString *> * pathList;
//@end

#define calloutKey CFSTR(kIOCalloutDeviceKey)
#define nameKey CFSTR(kIOTTYDeviceKey)

@implementation DeviceDiscovery : NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nameList = [[NSMutableArray alloc] init];
        self.pathList = [[NSMutableArray alloc] init];
    }
    return self;
}

//- (NSArray<NSString *> *) getNamesOfConnectedDevices {
//    return self.nameList;
//}
//
//- (NSArray<NSString *> *) getPathsOfConnectedDevices {
//    return self.pathList;
//}

/**
 Returns the device path from it's name.

 @param name the device's name
 @return the device's path or nil if it wasn't not found
 */
- (NSString *) pathForName:(NSString *) name {
    NSUInteger index = [self.pathList indexOfObject:name];
    if (index == -1) { return NULL; }
    return self.nameList[index];
}

/**
 Refreshes the local lists of names of and paths for the connected devices.
 */
- (void) refreshSerialList {
    if (self.nameList.count > 0 || self.pathList.count > 0) {
        [self.nameList removeAllObjects];
        [self.pathList removeAllObjects];
    }
    
    io_object_t serialPort;
    io_iterator_t serialPortIterator;
    
    // ask for all the serial ports
    IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
    
    // loop through all the serial ports and add them to the array
    while ((serialPort = IOIteratorNext(serialPortIterator))) {
        NSString * nameString = (__bridge NSString *)IORegistryEntryCreateCFProperty(serialPort, nameKey, kCFAllocatorDefault, 0);
        NSString * calloutString = (__bridge NSString *)IORegistryEntryCreateCFProperty(serialPort, calloutKey, kCFAllocatorDefault, 0);
        [self.nameList addObject: nameString];
        [self.pathList addObject: calloutString];
        IOObjectRelease(serialPort);
    }
    
    IOObjectRelease(serialPortIterator);
}

@end
