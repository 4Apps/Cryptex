//
//  CTextView.h
//  Cryptex
//
//  Created by Gints Murans on 29/10/14.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HGMarkdownHighlighter.h"

@interface CTextView : NSTextView

@property (nonatomic, retain) HGMarkdownHighlighter *hl;

@end
