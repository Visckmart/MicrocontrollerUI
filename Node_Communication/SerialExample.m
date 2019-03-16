//
//  SerialExample.m
//  Arduino Serial Example
//
//  Created by Gabe Ghearing on 6/30/09.
//

#import "SerialExample.h"
#import "HelperFunctions-ObjC.h"
#import "Node_Communication-Swift.h"
#include <sys/time.h>

@implementation SerialExample

NSString *const StartOfTextChar = @"";
NSString *const EndOfTextChar = @"";

// executes after everything in the xib/nib is initiallized
- (void)prepare {
	// we don't have a serial port open yet
	serialFileDescriptor = -1;
	self.readThreadRunning = FALSE;
    [self addObserver:self forKeyPath:@"readThreadRunning" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"readThreadRunning"]) {
        self.interface.isConnected = self.readThreadRunning;
        NSLog(@"Read thread changed to: %s", self.readThreadRunning ? "Running" : "Not running");
    }
}
// open the serial port
//   - nil is returned on success
//   - an error message is returned otherwise
- (NSString *)  openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate {
	int success;
	
	// close the port if it is already open
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
		
		// wait for the reading thread to die
		while(self.readThreadRunning);
		
		// re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
		sleep(0.5);
	}
	
	// c-string path to serial-port file
	const char *bsdPath = [serialPortFile cStringUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Connecting to: %s", bsdPath);
	// Hold the original termios attributes we are setting
	struct termios options;
	
	// receive latency ( in microseconds )
	unsigned long mics = 3;
	
	// error message string
	NSString *errorMessage = nil;
	
	// open the port
	//     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
    
	serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
	
	if (serialFileDescriptor == -1) {
		// check if the port opened correctly
		errorMessage = @"Couldn't open serial port";
	} else {
		// TIOCEXCL causes blocking of non-root processes on this serial-port
		success = ioctl(serialFileDescriptor, TIOCEXCL);
		if ( success == -1) {
			errorMessage = @"Couldn't obtain lock on serial port";
		} else {
			success = fcntl(serialFileDescriptor, F_SETFL, 0);
			if ( success == -1) {
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = @"Couldn't obtain lock on serial port";
			} else {
				// Get the current options and save them so we can restore the default settings later.
				success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
				if ( success == -1) {
					errorMessage = @"Couldn't get serial attributes";
				} else {
					// copy the old termios settings into the current
					//   you want to do this so that you get all the control characters assigned
					options = gOriginalTTYAttrs;
					
					/*
					 cfmakeraw(&options) is equivilent to:
					 options->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
					 options->c_oflag &= ~OPOST;
					 options->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
					 options->c_cflag &= ~(CSIZE | PARENB);
					 options->c_cflag |= CS8;
					 */
					cfmakeraw(&options);
					
					// set tty attributes (raw-mode in this case)
					success = tcsetattr(serialFileDescriptor, TCSANOW, &options);
					if ( success == -1) {
						errorMessage = @"Coudln't set serial attributes";
					} else {
						// Set baud rate (any arbitrary baud rate can be set this way)
						success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
						if ( success == -1) {
							errorMessage = @"Baud Rate out of bounds";
						} else {
							// Set the receive latency (a.k.a. don't wait to buffer data)
							success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
							if ( success == -1) {
								errorMessage = @"Couldn't set serial latency";
							}
						}
					}
				}
			}
		}
	}
	
	// make sure the port is closed if a problem happens
	if ((serialFileDescriptor == -1) && (errorMessage == nil)) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
        [self.interface logWithString:@"Connection error."];
//        [_interface updateConnectionStatusWithConnected: NO];
    } else {
        [self.interface logWithString:@"Successfully connected!"];
//        [_interface updateConnectionStatusWithConnected: YES];
    }
    
	return errorMessage;
}

- (void) closeSerialPort {
    self.readThreadRunning = FALSE;
    if (serialFileDescriptor != -1) {
        self.readThreadRunning = FALSE;
//        fflush(serialFileDescriptor);
        [self.interface stopReading];
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
        [self.interface logWithAttributedString:[Helper formatAsSpecialMessage:@"Serial port closed" withType:MessageType_Important]];
    }
    NSLog(@"is thread running %d", self.readThreadRunning);
    //    [_interface updateConnectionStatusWithConnected: NO];
}

- (void)treatCommandResponse:(NSString *)response withCompletionBlock:(void (^)(NSString *))completionBlock {
    if (commandRunning == none) {
        completionBlock(response);
        return;
    }
    NSRange start = [response rangeOfString:StartOfTextChar];
    NSRange end = [response rangeOfString:EndOfTextChar];
    if (accumulatingResponse == NO) {
        if (preparingToReadCommand == NO && start.location != NSNotFound) {
            preparingToReadCommand = YES;
        }
        if (preparingToReadCommand && end.location != NSNotFound) {
            preparingToReadCommand = NO;
            accumulatingResponse = YES;
            responseAccumulator = [NSMutableString string];
            NSRange rangeAfterHeader = NSMakeRange(end.location, [response length] - end.location);
            start = [response rangeOfString:StartOfTextChar options:0
                                      range:rangeAfterHeader];
            if (start.location != NSNotFound) {
                NSRange rangeOfBodySection = NSMakeRange(start.location, [response length] - start.location);
                end = [response rangeOfString:EndOfTextChar options:0
                                        range:rangeOfBodySection];
            } else {
                start = NSMakeRange(NSNotFound, 0);
                end = NSMakeRange(NSNotFound, 0);
                return;
            }
        }
    }
    if (accumulatingResponse == YES && (preparingToReadCommand == NO || (start.location != NSNotFound))){
        if (accumulatingResponse == YES && start.location == NSNotFound && end.location == NSNotFound) {
            [responseAccumulator appendString: response];
            return;
        }
        if (start.location != NSNotFound) {
            response = [response substringFromIndex:start.location];
            if (end.location == NSNotFound) {
                [responseAccumulator appendString: response];
            }
        }
        if (end.location != NSNotFound) {
            [responseAccumulator appendString: response];
            completionBlock([responseAccumulator copy]);
            responseAccumulator = nil;
            accumulatingResponse = NO;
            commandRunning = none;
        }
    }
}

// This selector/function will be called as another thread...
//  this thread will read from the serial port and exits when the port is closed
- (void)incomingTextUpdateThread: (NSThread *) parentThread {
	
	// mark that the thread is running
	self.readThreadRunning = TRUE;
	const int BUFFER_SIZE = 100;
	char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
	long numBytes=0; // number of bytes read during read
	NSString *text; // incoming text from the serial port
    responseAccumulator = [NSMutableString string];
    
    preparingToReadCommand = NO;
    accumulatingResponse = NO;
    
    int result;
    fd_set readset;
    
    // assign a high priority to this thread
	[NSThread setThreadPriority:1.0];
	
	// this will loop unitl the serial port closes
	while(self.readThreadRunning) {
//        NSLog(@"%@", self.readThreadRunning ? @"running" : @"stopped");
        
//        if (serialFileDescriptor == -1) { break; }
		// read() blocks until some data is available or the port is closed
        FD_ZERO(&readset);
        FD_SET(serialFileDescriptor, &readset);
        result = select(serialFileDescriptor + 1, &readset, NULL, NULL, NULL);
        if (result > 0) {
            if (FD_ISSET(serialFileDescriptor, &readset)) {
                /* The socket_fd has data available to be read */
                numBytes = read(serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
                if(numBytes>0) {
                    // create an NSString from the incoming bytes (the bytes aren't null terminated)
                    text = [NSString stringWithCString:byte_buffer length:numBytes];
                    //            NSLog(@"incoming: %@", text);
                    //                NSLog(@"-\n%@\n-", text);
                    [self treatCommandResponse:text withCompletionBlock:^(NSString * response) {
                        switch (self->commandRunning) {
                            case readingFiles:
                            {
                                NSArray * fileNames = [Helper filterFilenames:[response componentsSeparatedByString:@"\n"]];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self.interface.files = fileNames;
                                });
                                NSRange end = [response rangeOfString:EndOfTextChar options:NSBackwardsSearch];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.interface logWithString:[response substringFromIndex:end.location]];
                                    self->responseAccumulator = nil;
                                });
                                break;
                            }
                            default:
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.interface logWithString:response];
                                    //                            self->responseAccumulator = nil;
                                });
                                break;
                            }
                        }
                    }];
                }
            }
        } else {
            break; // Stop the thread if there is an error
        }
    }
	
	// make sure the serial port is closed
	if (serialFileDescriptor != -1) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
	
	// mark that the thread has quit
	self.readThreadRunning = FALSE;
}

- (void)runCommand: (NSString *)rawCommand withIdentifier:(CommandType)cmdType {
    [self runCommand:rawCommand withIdentifier:cmdType andMessage:NULL withMessageType:MessageType_Common];
}

- (void)runCommand: (NSString *)rawCommand withIdentifier:(CommandType)cmdType andMessage:(NSString *)message withMessageType:(MessageType)messageType {
    NSLog(@"%hhd", [self.interface checkIfCanRunCommand]);
    if (message != NULL) {
        [self.interface logWithAttributedString:[Helper formatAsSpecialMessage:message withType:messageType]];
    }
    commandRunning = cmdType;
    NSDictionary * dict = @{@"control begin":StartOfTextChar,
                            @"command":rawCommand,
                            @"control end":EndOfTextChar};
    Program * wrappedCommand = [self prepareProgram:@"CommandWrapper" withData:dict];
    [self writeString:wrappedCommand];
//    [self runCommand:rawCommand withIdentifier:cmdType];
}

- (Program *) prepareProgram: (NSString *)programName withData:(NSDictionary *) dataDict {
    NSString * uploadProgramPath = [[NSBundle mainBundle] pathForResource:programName ofType:@"lua"];
    
    NSString * content = [NSString stringWithContentsOfFile: uploadProgramPath
                                                   encoding: NSUTF8StringEncoding
                                                      error: nil];
    NSRegularExpression* regex = [NSRegularExpression
                                  regularExpressionWithPattern: @"<([A-Za-z\\s]+)>"
                                  options:0 error: nil];
    
    NSTextCheckingResult * matchRange = [regex firstMatchInString:content options:0 range:NSMakeRange(0, content.length)];
    while (matchRange != nil) {
        NSRange firstCapture = [matchRange rangeAtIndex:1];
        NSString * keySubstring = [content substringWithRange:firstCapture];
        NSString * value = [dataDict objectForKey:keySubstring];
        if (value == nil) {
            NSLog(@"Error at program preparation.");
            return NULL;
        }
        content = [content stringByReplacingCharactersInRange: matchRange.range
                                                   withString: dataDict[keySubstring]];
        
        matchRange = [regex firstMatchInString:content options:0 range:NSMakeRange(0, content.length)];
    }
    return [content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
}

// send a string to the serial port
- (void) writeString: (NSString *) str {
//    if(serialFileDescriptor!=-1) {
        NSString * temp = [str stringByAppendingString:[NSString stringWithFormat:@"%c%c", 13, 10]];
        NSLog(@"%s", [temp cStringUsingEncoding:NSASCIIStringEncoding]);
		write(serialFileDescriptor, [temp cStringUsingEncoding:NSASCIIStringEncoding], [temp length]);
//        sleep(1);
//    } else {
//        // make sure the user knows they should select a serial port
//        [self.interface logWithString:@"\n ERROR:  Select a Serial Port from the pull-down menu"];
//    }
}

// action from the reset button
- (IBAction) resetButton: (NSButton *) btn {
	// set and clear DTR to reset an arduino
	struct timespec interval = {0,100000000}, remainder;
	if(serialFileDescriptor!=-1) {
		ioctl(serialFileDescriptor, TIOCSDTR);
		nanosleep(&interval, &remainder); // wait 0.1 seconds
		ioctl(serialFileDescriptor, TIOCCDTR);
	}
}

@end
