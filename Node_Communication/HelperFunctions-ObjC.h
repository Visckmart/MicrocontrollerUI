//
//  HelperFunctions-ObjC.h
//  Node_Communication
//
//  Created by Victor Martins on 08/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef HelperFunctions_ObjC_h
#define HelperFunctions_ObjC_h

@interface Helper : NSObject
+ (NSArray *) filterFilenames:(NSArray *) stringArray;
+ (NSAttributedString *)formatAsSpecialMessage:(NSString *)rawString;
@end

#endif /* HelperFunctions_ObjC_h */
