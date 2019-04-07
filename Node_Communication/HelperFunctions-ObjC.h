//
//  HelperFunctions-ObjC.h
//  Node_Communication
//
//  Created by Victor Martins on 08/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MessageType.h"

#ifndef HelperFunctions_ObjC_h
#define HelperFunctions_ObjC_h

@interface Helper : NSObject
+ (NSArray *_Nonnull) filterFilenames:(NSArray *_Nonnull) stringArray;
+ (NSAttributedString * _Nonnull)formatAsSpecialMessage:(NSString *_Nonnull)rawString withType:(MessageType)messageType;
@end

#endif /* HelperFunctions_ObjC_h */
