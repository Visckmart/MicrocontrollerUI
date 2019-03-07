//
//  SerialExample.m
//  Arduino Serial Example
//
//  Created by Gabe Ghearing on 6/30/09.
//

#import "SerialExample.h"
#import "Node_Communication-Swift.h"

@implementation SerialExample

NSString *const StartOfTextChar = @"";
NSString *const EndOfTextChar = @"";

// executes after everything in the xib/nib is initiallized
- (void)prepare {
	// we don't have a serial port open yet
	serialFileDescriptor = -1;
	readThreadRunning = FALSE;
}

- (void) closeSerialPort {
    if (serialFileDescriptor != -1) {
        readThreadRunning = FALSE;
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
        
        // wait for the reading thread to die
//        while(readThreadRunning);
        
        // re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
//        sleep(0.5);
    }
    NSLog(@"is thread running %d", readThreadRunning);
    [_interface updateConnectionStatusWithConnected: NO];
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
		while(readThreadRunning);
		
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
		errorMessage = @"Error: couldn't open serial port";
	} else {
		// TIOCEXCL causes blocking of non-root processes on this serial-port
		success = ioctl(serialFileDescriptor, TIOCEXCL);
		if ( success == -1) {
			errorMessage = @"Error: couldn't obtain lock on serial port";
		} else {
			success = fcntl(serialFileDescriptor, F_SETFL, 0);
			if ( success == -1) {
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = @"Error: couldn't obtain lock on serial port";
			} else {
				// Get the current options and save them so we can restore the default settings later.
				success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
				if ( success == -1) {
					errorMessage = @"Error: couldn't get serial attributes";
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
						errorMessage = @"Error: coudln't set serial attributes";
					} else {
						// Set baud rate (any arbitrary baud rate can be set this way)
						success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
						if ( success == -1) {
							errorMessage = @"Error: Baud Rate out of bounds";
						} else {
							// Set the receive latency (a.k.a. don't wait to buffer data)
							success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
							if ( success == -1) {
								errorMessage = @"Error: coudln't set serial latency";
							}
						}
					}
				}
			}
		}
	}
	
	// make sure the port is closed if a problem happens
	if ((serialFileDescriptor == -1) && (errorMessage != nil)) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
        [self.interface logWithString:@"Connection error."];
        [_interface updateConnectionStatusWithConnected: NO];
    } else {
        [self.interface logWithString:@"Successfully connected!"];
        [_interface updateConnectionStatusWithConnected: YES];
    }
    
	return errorMessage;
}

- (NSArray *) filterFilenames:(NSArray *) stringArray {
    if (stringArray.count == 0) {
        return [NSArray array];
    }
    NSMutableArray * filteredArray = [NSMutableArray array];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(\\S+)\\s*$" options:0 error:nil];
    for (NSString * name in stringArray) {
        NSRange nameRange = NSMakeRange(0, [name length]);
        NSTextCheckingResult * firstMatch = [regex firstMatchInString:name options:0 range:nameRange];
        if (firstMatch != NULL) {
            NSString * trimmedName = [name substringWithRange: [firstMatch rangeAtIndex:1]];
            [filteredArray addObject: trimmedName];
        }
    }
    return [filteredArray copy];
}

// This selector/function will be called as another thread...
//  this thread will read from the serial port and exits when the port is closed
- (void)incomingTextUpdateThread: (NSThread *) parentThread {
	
	// mark that the thread is running
	readThreadRunning = TRUE;
	const int BUFFER_SIZE = 100;
	char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
	long numBytes=0; // number of bytes read during read
	NSString *text; // incoming text from the serial port
    NSMutableString * acc = [NSMutableString string];
    
    BOOL preparingToReadFileList = NO;
    BOOL readingFileList = NO;
    
	// assign a high priority to this thread
	[NSThread setThreadPriority:1.0];
	
	// this will loop unitl the serial port closes
	while(readThreadRunning) {
        if (serialFileDescriptor == -1) { break; }
		// read() blocks until some data is available or the port is closed
		numBytes = read(serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
		if(numBytes>0) {
			// create an NSString from the incoming bytes (the bytes aren't null terminated)
			text = [NSString stringWithCString:byte_buffer length:numBytes];
//            NSLog(@"incoming: %@", text);
			// this text can't be directly sent to the text area from this thread
			//  BUT, we can call a selctor on the main thread.
            if (!readingFiles) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.interface logWithString:text];
                });
            } else {
                NSLog(@"Reading files");
//                NSLog(@"-\n%@\n-", text);
                NSRange start = [text rangeOfString:StartOfTextChar];
                NSRange end = [text rangeOfString:EndOfTextChar];
                if (readingFileList == NO) {
                    if (preparingToReadFileList == NO && start.location != NSNotFound) {
                        preparingToReadFileList = YES;
                    } else if (preparingToReadFileList && end.location != NSNotFound) {
                        preparingToReadFileList = NO;
                        readingFileList = YES;
                    }
                } else {
                    if (start.location != NSNotFound && end.location != NSNotFound) {
                        NSString * trimmed = [[text substringFromIndex:start.location] substringToIndex:end.location];
                        [acc appendString: trimmed];
                    } else if (start.location != NSNotFound) {
                        [acc appendString: [text substringFromIndex:start.location]];
                    } else if (end.location != NSNotFound) {
                        [acc appendString: [text substringToIndex:end.location]];
                        readingFileList = NO;
                        NSArray * fileNames = [self filterFilenames:[acc componentsSeparatedByString:@"\n"]];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"f is %@", fileNames);
                            self.interface.files = fileNames;
                            [acc setString:@""];
                        });
                        readingFiles = NO;
                    } else {
                        [acc appendString: text];
                    }
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
	readThreadRunning = FALSE;
}

- (NSArray *) refreshSerialList {
    NSMutableArray * serialList = [[NSMutableArray alloc] init];
    
	io_object_t serialPort;
	io_iterator_t serialPortIterator;
	
	// ask for all the serial ports
	IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
	
	// loop through all the serial ports and add them to the array
	while ((serialPort = IOIteratorNext(serialPortIterator))) {
		[serialList addObject:
         (__bridge NSString*)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0)];
		IOObjectRelease(serialPort);
	}
	
	IOObjectRelease(serialPortIterator);
    return [serialList copy];
}

- (void) restart {
    [self writeString:@"node.restart()"];
}

- (void) runFile: (NSString *) fileName {
    [self writeString:[NSString stringWithFormat:@"dofile(\"%@\")", fileName]];
}

- (void) readFiles {
    readingFiles = TRUE;
    NSString * command = [NSString stringWithFormat:@"print('%@') for name in pairs(file.list()) do print(name) end print('\\r\\r%@')", StartOfTextChar, EndOfTextChar];
    [self writeString:command];
}

typedef NSString Program;
- (Program *) prepareProgram: (NSString *)programName withData:(NSDictionary *) dataDict {
    NSString * uploadProgramPath = [[NSBundle mainBundle] pathForResource:programName ofType:@"lua"];
    
    NSString * content = [NSString stringWithContentsOfFile: uploadProgramPath
                                                   encoding: NSUTF8StringEncoding
                                                      error: nil];
    NSRegularExpression* regex = [NSRegularExpression
                                  regularExpressionWithPattern: @"<([A-Za-z]+)>"
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

- (void) uploadFile:(NSURL *)filePath {
    NSData * file = [NSData dataWithContentsOfURL:filePath];
    if (file == nil) {
        NSLog(@"Upload aborted because the file couldn't be loaded.");
        return;
    }
    NSNumber * dataSize = @([file length] + 2);
    
    NSDictionary * dict = [NSDictionary dictionaryWithObjects: @[filePath.lastPathComponent, dataSize.stringValue] forKeys: @[@"filename", @"filesize"]];
    
    Program * prepareFileUpload = [self prepareProgram:@"FileUpload_Start" withData:dict];
    NSLog(@"\n--File--\n%@\n--------", prepareFileUpload);
    if (prepareFileUpload == NULL) {
        NSLog(@"Upload aborted because it couldn't be prepared.");
        return;
    }
    NSString * fileContent = [[NSString alloc] initWithData: file encoding: NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self writeString: prepareFileUpload];
        [self writeString: fileContent];
    });
}

// send a string to the serial port
- (void) writeString: (NSString *) str {
	if(serialFileDescriptor!=-1) {
        NSString * temp = [str stringByAppendingString:[NSString stringWithFormat:@"%c%c", 13, 10]];
        NSLog(@"%s", [temp cStringUsingEncoding:NSASCIIStringEncoding]);
		write(serialFileDescriptor, [temp cStringUsingEncoding:NSASCIIStringEncoding], [temp length]);
//        sleep(1);
	} else {
		// make sure the user knows they should select a serial port
		[self.interface logWithString:@"\n ERROR:  Select a Serial Port from the pull-down menu"];
	}
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
