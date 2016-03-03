//
//  CTableView.m
//  Cryptex
//
//  Created by Gints Murans on 30/10/14.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import "CTableView.h"

@implementation CTableView

- (NSFocusRingType)focusRingType
{
    return NSFocusRingTypeNone;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    if (self.cDelegate != nil && [self.cDelegate respondsToSelector:@selector(CTableTextDidEndEditing:)])
    {
        NSTextView *textView = (NSTextView *)notification.object;
        [self.cDelegate CTableTextDidEndEditing:textView.string];
    }
    [super textDidEndEditing:notification];
}

@end
