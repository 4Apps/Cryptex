//
//  SFDefaultTab.m
//  tabtest
//
//  Created by Matteo Rattotti on 2/28/10.
//  Copyright 2010 www.shinyfrog.net. All rights reserved.
//

#import "SFDefaultTab.h"


@implementation SFLabelLayer
- (BOOL)containsPoint:(CGPoint)p
{
    return FALSE;
}
@end



@implementation SFCloseLayer
- (BOOL)containsPoint:(CGPoint)p
{
    return FALSE;
}
@end



@implementation SFDefaultTab


#pragma mark - Setters

- (void)setSelected:(BOOL)selected
{
    _selected = selected;

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if (selected == YES)
    {
        [self setContents:_activeTab];
        _tabLabel.foregroundColor = _tabLabelActiveColor;
        _closeLayer.hidden = NO;
    }
    else
    {
        [self setContents:_inactiveTab];
        _tabLabel.foregroundColor = _tabLabelInactiveColor;
        _closeLayer.hidden = YES;
    }
    [CATransaction commit];
}


- (void)setTabLabelFont:(NSFont *)tabLabelFont
{
    _tabLabelFont = tabLabelFont;
    _tabLabel.font = (__bridge CFTypeRef)(_tabLabelFont.familyName);
    _tabLabel.fontSize = _tabLabelFont.pointSize;
}


- (void)setTabLabelActiveColor:(CGColorRef)tabLabelActiveColor
{
    _tabLabelActiveColor = tabLabelActiveColor;
    if (self.selected == YES)
    {
        _tabLabel.foregroundColor = _tabLabelActiveColor;
    }
}


- (void)setTabLabelInactiveColor:(CGColorRef)tabLabelInactiveColor
{
    _tabLabelInactiveColor = tabLabelInactiveColor;
    if (self.selected == YES)
    {
        _tabLabel.foregroundColor = _tabLabelInactiveColor;
    }
}


#warning TODO: update _representedObject, probably should make sure its always nsmutabledictionary
- (void)setLabelName:(NSString *)name
{
    _tabLabel.string = name;
}


#pragma mak - Helpers

- (void)setRepresentedObject:(id)representedObject
{
    CAConstraintLayoutManager *layout = [CAConstraintLayoutManager layoutManager];
    [self setLayoutManager:layout];

    _representedObject = representedObject;

    if (!_activeTab)
    {
        _activeTab = [NSImage imageNamed:@"activeTab"];
		_inactiveTab = [NSImage imageNamed:@"inactiveTab"];
    }
    self.frame = CGRectMake(0, 0, _activeTab.size.width, _activeTab.size.height);

    [self setContents:_inactiveTab];

    _tabLabel = [SFLabelLayer layer];
    if (representedObject[@"name"] != nil)
    {
        _tabLabel.string = representedObject[@"name"];
    }
    _tabLabel.font = (__bridge CFTypeRef)(_tabLabelFont.familyName);
    _tabLabel.fontSize = _tabLabelFont.pointSize;
    _tabLabel.shadowOpacity = 0.2f;
    _tabLabel.shadowOffset = CGSizeMake(0, -1);
    _tabLabel.shadowRadius = 1.0f;
    _tabLabel.shadowColor = CGColorCreateGenericRGB(1, 1, 1, 1);
    _tabLabel.foregroundColor = _tabLabelInactiveColor;
    _tabLabel.truncationMode = kCATruncationEnd;
    _tabLabel.alignmentMode = kCAAlignmentCenter;
    CAConstraint *constraint = [CAConstraint constraintWithAttribute:kCAConstraintMidX
                                                          relativeTo:@"superlayer"
                                                           attribute:kCAConstraintMidX];
    [_tabLabel addConstraint:constraint];

    constraint = [CAConstraint constraintWithAttribute:kCAConstraintMidY
                                            relativeTo:@"superlayer"
                                             attribute:kCAConstraintMidY
                                                offset:-2.0];
    [_tabLabel addConstraint:constraint];

    constraint = [CAConstraint constraintWithAttribute:kCAConstraintMaxX
                                            relativeTo:@"superlayer"
                                             attribute:kCAConstraintMaxX
                                                offset:-25.0];
    [_tabLabel addConstraint:constraint];

    constraint = [CAConstraint constraintWithAttribute:kCAConstraintMinX
                                            relativeTo:@"superlayer"
                                             attribute:kCAConstraintMinX
                                                offset:20.0];
    [_tabLabel addConstraint:constraint];

    [self addSublayer:_tabLabel];
    [self setupCloseButton];
}


- (void)setupCloseButton
{
    _closeButton = [NSImage imageNamed:@"tabClose"];
    _closeButtonHover = [NSImage imageNamed:@"tabCloseHover"];
    _closeButtonActive = [NSImage imageNamed:@"tabCloseActive"];

    _closeLayer = [[SFCloseLayer alloc] init];
    _closeLayer.frame = NSMakeRect(self.frame.size.width - _closeButton.size.width - 15.0, round((self.frame.size.height - _closeButton.size.height) / 2.0) - 2.0, _closeButton.size.width, _closeButton.size.height);
    _closeLayer.contents = _closeButton;
    _closeLayer.hidden = YES;
    _closeLayerHovered = NO;

    [self addSublayer:_closeLayer];
}


- (BOOL)overCloseButton:(NSPoint)point
{
    return point.x < _closeLayer.frame.size.width && point.x > 0 && point.y < _closeLayer.frame.size.height && point.y > 0;
}


- (void)mousemove:(NSPoint)point
{
    CGPoint relative = [_closeLayer convertPoint:point fromLayer:self.superlayer];
    if ([self overCloseButton:relative])
    {
        if (_closeLayerHovered == NO)
        {
            _closeLayer.contents = _closeButtonHover;
            _closeLayerHovered = YES;
        }
    }
    else
    {
        if (_closeLayerHovered == YES)
        {
            _closeLayer.contents = _closeButton;
            _closeLayerHovered = NO;
        }
    }
}

- (void)mouseDown
{
    _closeLayer.contents = _closeButtonActive;
}

@end
