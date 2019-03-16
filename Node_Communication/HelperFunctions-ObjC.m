//
//  HelperFunctions-ObjC.m
//  Node_Communication
//
//  Created by Victor Martins on 08/03/19.
//  Copyright © 2019 Visckmart. All rights reserved.
//

#import "HelperFunctions-ObjC.h"
#import <Foundation/Foundation.h>

@implementation Helper

+ (NSArray *) filterFilenames:(NSArray *) stringArray {
    if (stringArray.count == 0) {
        return [NSArray array];
    }
    NSMutableArray * filteredArray = [NSMutableArray array];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*([A-Za-z0-9\\.-]+)\\s*$" options:0 error:nil];
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

+ (NSAttributedString *)formatAsSpecialMessage:(NSString *)rawString {
    NSMutableAttributedString * message = [[NSMutableAttributedString alloc] initWithString:rawString];
    NSRange messageRange = NSMakeRange(0, message.length);
    
    NSFontDescriptor * fontDescriptor = [[NSFont systemFontOfSize:12] fontDescriptor];
    fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:[fontDescriptor symbolicTraits] | NSFontItalicTrait];
    NSFont * fontWithStyle = [NSFont fontWithDescriptor:fontDescriptor size:12];
    [message addAttribute:NSFontAttributeName value:fontWithStyle range:messageRange];
    [message addAttribute:NSForegroundColorAttributeName value:[NSColor darkGrayColor] range:messageRange];
    return [message copy];
}

@end
