//
//  SerialExample.h
//  Arduino Serial Example
//
//  Created by Gabe Ghearing on 6/30/09.
//

#import <Cocoa/Cocoa.h>

//#import "Node_Communication-Swift.h"
// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>

@protocol Writes;
@interface SerialExample : NSObject {
	IBOutlet NSPopUpButton *serialListPullDown;
	IBOutlet NSTextView *serialOutputArea;
	IBOutlet NSTextField *serialInputField;
	IBOutlet NSTextField *baudInputField;
	int serialFileDescriptor; // file handle to the serial port
	struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
	bool readThreadRunning;
	NSTextStorage *storage;
    NSThread * bg;
}
@property (weak) id <Writes> interface;
- (void) prepare;
//- (void) callSelec;
- (void) restart;
- (void) closeSerialPort;
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
//- (void)appendToIncomingText: (id) text;
- (void)incomingTextUpdateThread: (NSThread *) parentThread;
- (NSArray *) refreshSerialList;
- (void) writeString: (NSString *) str;
//- (void) writeByte: (uint8_t *) val;
//- (IBAction) serialPortSelected: (id) cntrl;
//- (IBAction) baudAction: (id) cntrl;
//- (IBAction) refreshAction: (id) cntrl;
//- (IBAction) sendText: (id) cntrl;
//- (IBAction) sliderChange: (NSSlider *) sldr;
//- (IBAction) hitAButton: (NSButton *) btn;
//- (IBAction) hitBButton: (NSButton *) btn;
//- (IBAction) hitCButton: (NSButton *) btn;
- (IBAction) resetButton: (NSButton *) btn;

@end
