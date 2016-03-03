//
//  Extensions.m
//  Cryptex
//
//  Created by Gints Murans on 19/08/2014.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import "Extensions.h"

@implementation NSColor (Extensions)

+ (NSColor *)colorWithR:(CGFloat)red g:(CGFloat)green b:(CGFloat)blue alpha:(CGFloat)alpha
{
    return [self colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha];
}

@end



@implementation NSTextFieldCell (Extensions)

//- (NSRect)titleRectForBounds:(NSRect)frame
//{
//    CGFloat stringHeight = self.attributedStringValue.size.height;
//    NSRect titleRect = [super titleRectForBounds:frame];
//    titleRect.origin.y = frame.origin.y + (frame.size.height - stringHeight) / 2.0;
//    return titleRect;
//}
//
//
//- (void)drawInteriorWithFrame:(NSRect)cFrame inView:(NSView*)cView
//{
//    [super drawInteriorWithFrame:[self titleRectForBounds:cFrame] inView:cView];
//}

@end