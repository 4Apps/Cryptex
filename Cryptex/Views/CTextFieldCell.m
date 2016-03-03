//
//  CTextFieldCell.m
//  Cryptex
//
//  Created by Gints Murans on 30/10/14.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import "CTextFieldCell.h"
#import "Extensions.h"

@implementation CTextFieldCell

- (void)awakeFromNib
{
    self.font = [NSFont fontWithName:@"Open Sans" size:13.0];
    self.bezelStyle = NSRoundedBezelStyle;
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
    [(NSTextView *)textObj setTextContainerInset:NSMakeSize(5.0, 0)];
    return textObj;
}


- (NSRect)drawingRectForBounds:(NSRect)rect
{
    NSRect rectInset = NSMakeRect(rect.origin.x + 10.0, rect.origin.y, rect.size.width - 20.0, rect.size.height);
    return [super drawingRectForBounds:rectInset];
}


- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    self.textColor = [NSColor colorWithR:0 g:0 b:0 alpha:1.0];
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}


- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    BOOL isFocused = ([[self controlView] isEqualTo:[[[self controlView] window] firstResponder]]);
    if (highlighted == YES && isFocused == YES)
    {
        self.textColor = [NSColor whiteColor];
    }
    else
    {
        self.textColor = [NSColor colorWithR:119.0 g:119.0 b:119.0 alpha:1.0];
    }
}


@end
