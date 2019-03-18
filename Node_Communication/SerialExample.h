//
//  SerialExample.h
//  Arduino Serial Example
//
//  Created by Gabe Ghearing on 6/30/09.
//

#import <Cocoa/Cocoa.h>

#import "MessageType.h"
//#import "Node_Communication-Swift.h"
// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>

@protocol Writes;

typedef NS_ENUM(NSInteger, CommandType) {
    none = 0,
    readingFiles,
    common
};

@interface SerialExample : NSObject {
	struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
    NSThread * bg;
    NSString * filesOutput;
    CommandType commandRunning;
    __block NSMutableString * responseAccumulator;
    BOOL readThreadRunning;
}
@property (weak) NSObject <Writes> * interface;
@property (atomic) int serialFileDescriptor; // file handle to the serial port
@property (atomic) BOOL preparingToReadCommand;
@property (atomic) BOOL accumulatingResponse;
@property (atomic) BOOL canWrite;
- (void)setWriteAvailability:(bool)status;
@property (atomic) NSMutableArray * commandQueue;
@property (atomic) NSMutableArray<NSNumber *> * commandTypeQueue;
- (void) prepare;
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
- (void) closeSerialPort;
- (void)runCommand:(NSString *)rawCommand withIdentifier:(CommandType)cmdType;
- (void)runCommand:(NSString *)rawCommand withIdentifier:(CommandType)cmdType
        andMessage:(NSString *)message withMessageType:(MessageType)messageType;
typedef NSString Program;
- (Program *) prepareProgram:(NSString *)programName withData:(NSDictionary *) dataDict;
- (void) writeString:(NSString *) str;
//- (IBAction) resetButton: (NSButton *) btn;

@end
