//
//  SFDefaultTab.h
//  tabtest
//
//  Created by Matteo Rattotti on 2/28/10.
//  Copyright 2010 www.shinyfrog.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "SFTabView.h"



@interface SFLabelLayer : CATextLayer
@end



@interface SFCloseLayer : CALayer
@end



@interface SFDefaultTab : CALayer
{
    id _representedObject;

    NSImage *_activeTab;
    NSImage *_inactiveTab;
    SFLabelLayer *_tabLabel;

    // Close layer
    SFCloseLayer *_closeLayer;
    NSImage *_closeButton;
    NSImage *_closeButtonHover;
    NSImage *_closeButtonActive;
}

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL closeLayerHovered;
@property (nonatomic, retain) NSFont *tabLabelFont;
@property (nonatomic, assign) CGColorRef tabLabelActiveColor;
@property (nonatomic, assign) CGColorRef tabLabelInactiveColor;

- (void)mouseDown;
- (void)mousemove:(NSPoint)point;
- (void)setRepresentedObject:(id)representedObject;
- (void)setLabelName:(NSString *)name;

@end
