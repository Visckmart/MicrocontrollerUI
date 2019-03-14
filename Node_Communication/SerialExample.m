//
//  SerialExample.m
//  Arduino Serial Example
//
//  Created by Gabe Ghearing on 6/30/09.
//

#import "SerialExample.h"
#import "HelperFunctions-ObjC.h"
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

- (void) fileReadingProcedure:(NSString *) commandResponse {
    NSArray * fileNames = [Helper filterFilenames:[commandResponse componentsSeparatedByString:@"\n"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"f is %@", fileNames);
        self.interface.files = fileNames;
    });
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
	readThreadRunning = TRUE;
	const int BUFFER_SIZE = 100;
	char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
	long numBytes=0; // number of bytes read during read
	NSString *text; // incoming text from the serial port
    responseAccumulator = [NSMutableString string];
    
    preparingToReadCommand = NO;
    accumulatingResponse = NO;
    
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
//                NSLog(@"-\n%@\n-", text);
            [self treatCommandResponse:text withCompletionBlock:^(NSString * response) {
                switch (self->commandRunning) {
                    case readingFiles:
                    {
                        [self fileReadingProcedure:response];
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

/**
 Returns a list with the path (/dev/...) of the connected devices.

 @return A NSArray with NSString as element type.
 */
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
    // kIOTTYDeviceKey pega o nome dos dispositivos (sem /dev/cu. no início)
	
	IOObjectRelease(serialPortIterator);
    return [serialList copy];
}

- (void)runCommand: (NSString *)rawCommand withIdentifier:(CommandType)cmdType {
    commandRunning = cmdType;
    NSString * formattedCommand =  [NSString stringWithFormat:
                                    @"print('%@') "
                                    @"local success,error=pcall(function() %@ end)"
                                    @"if not success then "
                                    @"uart.write(0, 'Error :/\\n'..error) end "
                                    @"print('%@')",
                                    StartOfTextChar, rawCommand, EndOfTextChar];
    [self writeString:formattedCommand];
}

- (void)runCommand: (NSString *)rawCommand withIdentifier:(CommandType)cmdType andMessage:(NSString *)message {
    [self.interface logWithAttributedString:[Helper formatAsSpecialMessage:message]];
    [self runCommand:rawCommand withIdentifier:cmdType];
}

/**
 Restarts the connected device.
 */
- (void) restart {
    [self writeString:@"node.restart()"];
}

/**
 Runs a file on the connected device using 'dofile(filename)'.

 @param fileName The full name of the file to be run.
 (Not a path because there's no such thing on the device)
 */
- (void) runFile: (NSString *) fileName {
    NSString * message = [NSString stringWithFormat:@"Running \"%@\"", fileName];
    NSString * command = [NSString stringWithFormat:@"dofile(\"%@\")", fileName];
    [self runCommand:command withIdentifier:common andMessage:message];
}

/**
 Runs the command to refresh the files' list.
 When the response is complete, the incomingTextUpdateThread will
 update the UI properly.
 */
- (void) readFiles {
    NSString * command = @"for name in pairs(file.list()) do print(name) end";
    [self runCommand:command withIdentifier:readingFiles andMessage:@"Update files list"];
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
    Program * prepareFileUpload = [self prepareProgram:@"FileUpload_Start" withData:dict];
    NSLog(@"\n--File--\n%@\n--------", prepareFileUpload);
    if (prepareFileUpload == NULL) { // If the program couldn't be loaded
        NSLog(@"Upload aborted because it couldn't be prepared.");
        return;
    }
    
    // Load the contents of the file onto a NSString
    NSString * fileContent = [[NSString alloc] initWithData: file encoding: NSUTF8StringEncoding];
    
    // Effectively uploads the file
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
