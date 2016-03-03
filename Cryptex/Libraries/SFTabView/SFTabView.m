//
//  SFTabView.m
//  tabtest
//
//  Created by Matteo Rattotti on 2/27/10.
//  Copyright 2010 www.shinyfrog.net. All rights reserved.
//

#import "SFTabView.h"
#import "SFDefaultTab.h"



#pragma mark - Private Methods

@interface SFTabView (Private)

- (CALayer *)tabsLayer;
- (CAScrollLayer *)scrollLayer;

- (void)setupObservers;
- (void)setDefaults;
- (void)adjustTabLayerScrollAnimated:(BOOL)animated;
- (void)rearrangeInitialTab:(CALayer *)initialTab toLandingTab:(CALayer *)landingTab withCurrentPoint:(CGPoint)currentPoint direction:(BOOL)direction;

- (NSArray *)tabSequenceForStartingTabIndex:(int)startingIndex endingTabIndex:(int)endingIndex direction:(BOOL)direction;
- (int)startingXOriginForTabAtIndex:(int)index;
- (CABasicAnimation *)tabMovingAnimation;
- (NSPoint)deltaFromStartingPoint:(NSPoint)startingPoint endPoint:(NSPoint)endPoint;

@end



#pragma mark - SFTabView Implementation
@implementation SFTabView

#pragma mark - Constructors

- (void) awakeFromNib
{
    [self setDefaults];
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setDefaults];
    }
    return self;
}



#pragma mark - Defaults

- (void)setDefaults
{
    // Set some defaults
    _arrangedTabs = [[NSMutableArray alloc] init];
    _tabOffset = -20;
    _startingOffset = 20;
    _tabMagneticForce = 5;

    _bottomBorderColor = [NSColor colorWithDeviceRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0];
    _bottomBorderWidth = 1.0;
    _showBottomBorder = YES;

    _tabLabelFont = [NSFont fontWithName:@"Helvetica Neue" size:14.0];
    _tabLabelActiveColor = [NSColor blackColor];
    _tabLabelInactiveColor = [NSColor colorWithRed:102.0 / 255.0 green:102.0 / 255.0 blue:102.0 / 255.0 alpha:1.0];

    // Background layer
    CALayer *bgLayer = [CALayer layer];
    bgLayer.frame = NSRectToCGRect([self bounds]);
    bgLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    [self setLayer:bgLayer];
    [self setWantsLayer:YES];

    // Bottom border layer
    _bottomBorderLayer = [CALayer layer];
    _bottomBorderLayer.frame = NSMakeRect(0, 0, self.bounds.size.width, _bottomBorderWidth);
    _bottomBorderLayer.autoresizingMask = kCALayerWidthSizable;
    _bottomBorderLayer.backgroundColor = _bottomBorderColor.CGColor;
    _bottomBorderLayer.hidden = (_showBottomBorder == NO);
    [self.layer addSublayer:_bottomBorderLayer];

    // Add other layers and setup observers
    [self.layer addSublayer:[self scrollLayer]];
    [self setupObservers];
}


#pragma mark - Setters

- (void)setBottomBorderColor:(NSColor *)bottomBorderColor
{
    _bottomBorderColor = bottomBorderColor;
    _bottomBorderLayer.backgroundColor = _bottomBorderColor.CGColor;
}

- (void)setBottomBorderWidth:(double)bottomBorderWidth
{
    _bottomBorderWidth = bottomBorderWidth;
    _bottomBorderLayer.frame = NSMakeRect(0, 0, self.bounds.size.width, _bottomBorderWidth);
}

- (void)setShowBottomBorder:(BOOL)showBottomBorder
{
    _showBottomBorder = showBottomBorder;
    _bottomBorderLayer.hidden = (_showBottomBorder == NO);
}


#pragma mark - Obververs

- (void)setupObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(frameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
}


- (void)frameDidChange:(id)sender
{
    [self adjustTabLayerScrollAnimated:NO];
}


- (void)adjustTabLayerScrollAnimated:(BOOL)animated
{
    if (_currentSelectedTab == nil)
    {
        return;
    }

    CGRect currentSelFrame = _currentSelectedTab.frame;
    currentSelFrame.size.width += round(currentSelFrame.size.width / 2.0);

    // Scrolling to maintain the selected tab visible
    if (CGRectContainsRect(_tabsLayer.visibleRect, currentSelFrame) == NO)
    {
        [self scrollToTab:_currentSelectedTab animated:NO];
    }

    // eventually scrolling back if the tabview frame expanded
    if (_tabsLayer.visibleRect.size.width < ([self bounds].size.width - ([self lastTab].frame.size.width / 2.0)) && _tabsLayer.visibleRect.origin.x > 0)
    {
        float deltaX = ([self bounds].size.width - round([self lastTab].frame.size.width / 2.0)) - _tabsLayer.visibleRect.size.width;

        float newTabXPosition = _tabsLayer.visibleRect.origin.x - deltaX;
        if (newTabXPosition < 0)
        {
            newTabXPosition = 0;
        }

        [self scrollToPoint:CGPointMake(newTabXPosition,0) animated:animated];
    }

}



#pragma mark - Base Layers

- (CALayer *)tabsLayer
{
    _tabsLayer = [CALayer layer];
    _tabsLayer.name = @"tabsLayer";

    _tabsLayer.layoutManager = [CAConstraintLayoutManager layoutManager];

    [_tabsLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];
    [_tabsLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
    [_tabsLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];

    NSMutableDictionary *actions = [NSMutableDictionary dictionaryWithDictionary:[_tabsLayer actions]];
    actions[@"onOrderIn"] = [NSNull null];
    actions[@"onOrderOut"] = [NSNull null];
    actions[@"position"] = [NSNull null];
    actions[@"bounds"] = [NSNull null];
    actions[@"contents"] = [NSNull null];
    actions[@"sublayers"] = [NSNull null];

    [_tabsLayer setActions:actions];
    return _tabsLayer;
}


- (CAScrollLayer *)scrollLayer
{
    _scrollLayer = [CAScrollLayer layer];
    _scrollLayer.name = @"scrollLayer";

    _scrollLayer.layoutManager = [CAConstraintLayoutManager layoutManager];

    [_scrollLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
    [_scrollLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
    [_scrollLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
    [_scrollLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
    [_scrollLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth]];
    [_scrollLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight]];

    NSMutableDictionary *actions = [NSMutableDictionary dictionaryWithDictionary:[_scrollLayer actions]];
    actions[@"position"] = [NSNull null];
    actions[@"bounds"] = [NSNull null];
    actions[@"sublayers"] = [NSNull null];
    actions[@"contents"] = [NSNull null];

    [_scrollLayer setActions:actions];

    [_scrollLayer addSublayer:[self tabsLayer]];
    return _scrollLayer;
}



#pragma mark - Mouse Handling

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // Getting clicked point.
    NSPoint mousePointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

    mousePointInView = [self.layer convertPoint:mousePointInView toLayer:_tabsLayer];
    _mouseDownPoint = mousePointInView;

    // Checking if a tab was clicked.
    SFDefaultTab *clickedLayer = (SFDefaultTab *)[_tabsLayer hitTest:mousePointInView];

    if (clickedLayer && [clickedLayer isEqualTo:_tabsLayer] == NO && _currentSelectedTab.closeLayerHovered == NO)
    {
        _canDragTab = NO;
        BOOL shouldSelectTab = YES;

        // Asking delegate if the tab can be selected.
        if ([_delegate respondsToSelector:@selector(tabView:shouldSelectTab:)])
        {
            shouldSelectTab = [_delegate tabView:self shouldSelectTab:clickedLayer];
        }
        if (shouldSelectTab)
        {
            [self selectTab:clickedLayer];
            _mouseDownStartingPoint = _currentSelectedTab.frame.origin;
            _currentClickedTab = clickedLayer;
        }

    }
    else if (_currentSelectedTab.closeLayerHovered == NO)
    {
        // Adapted from http://stackoverflow.com/a/15095645
        NSWindow *window = [self window];
        NSPoint mouseLocation = [window convertBaseToScreen:[theEvent locationInWindow]];
        NSPoint origin = [window frame].origin;
        // Now we loop handling mouse events until we get a mouse up event.
        while ((theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask|NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp))
        {
            @autoreleasepool
            {
                NSPoint currentLocation = [window convertBaseToScreen:[theEvent locationInWindow]];
                origin.x += currentLocation.x-mouseLocation.x;
                origin.y += currentLocation.y-mouseLocation.y;
                // Move the window by the mouse displacement since the last event.
                [window setFrameOrigin:origin];
                mouseLocation = currentLocation;
            }
        }
        [self mouseUp:theEvent];
        return;
    }
    else
    {
        [_currentSelectedTab mouseDown];
    }
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    // convert to local coordinate system
    NSPoint mousePointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
    mousePointInView = [self.layer convertPoint:mousePointInView toLayer:_tabsLayer];

    if (_currentClickedTab)
    {
        NSPoint deltaPoint = [self deltaFromStartingPoint:_mouseDownPoint endPoint:mousePointInView];

        // Getting drag direction, positive value mean right.
        BOOL rightShift = (deltaPoint.x > 0);

        // Applying magnetic force, prevent dragging tab if the drag distance is < than tabMagneticForce.
        if (rightShift && mousePointInView.x > _mouseDownPoint.x + _tabMagneticForce)
        {
            _canDragTab = YES;
        }
        else if (mousePointInView.x < _mouseDownPoint.x - _tabMagneticForce)
        {
            _canDragTab = YES;
        }

        if (_canDragTab == NO)
        {
            return;
        }

        CGPoint tabNewOrigin = CGPointMake(_currentClickedTab.frame.origin.x + deltaPoint.x, _currentClickedTab.frame.origin.y);
        CGRect newFrame = _currentClickedTab.frame;


        // Checking if the dragged tab crossed another tab.
        CGPoint proximityLayerPoint;

        if (rightShift)
        {
            proximityLayerPoint = CGPointMake(tabNewOrigin.x + (_currentClickedTab.frame.size.width), tabNewOrigin.y);
        }
        else
        {
            proximityLayerPoint = CGPointMake(tabNewOrigin.x, tabNewOrigin.y);
        }

        CALayer *la = [_tabsLayer hitTest:proximityLayerPoint];

        // if the drag is outside the tabview range we'll adjust the crossed tab to be the first or the last.
        if ((!la || la == _tabsLayer) && proximityLayerPoint.x < _startingOffset)
        {
            la = [self firstTab];
        }
        else if ((!la || la == _tabsLayer) && proximityLayerPoint.x > [[self lastTab] frame].size.width + [[self lastTab] frame].origin.x)
        {
            la = [self lastTab];
        }

        // If the tab is different than the tab view layer and than the selected one we'll rearrange tabs.
        if (la && la != _currentClickedTab && la != _tabsLayer)
        {
            [self rearrangeInitialTab:_currentClickedTab toLandingTab:la withCurrentPoint:proximityLayerPoint direction:rightShift];
        }

        // Moving the dragged tab according.
        newFrame.origin.x = tabNewOrigin.x;
        if (newFrame.origin.x < _startingOffset)
        {
            newFrame.origin.x = _startingOffset;
        }
        else if (newFrame.origin.x + newFrame.size.width > _tabsLayer.frame.size.width)
        {
            newFrame.origin.x = _tabsLayer.frame.size.width - newFrame.size.width;
        }

        if (CGRectContainsRect(_tabsLayer.frame, newFrame))
        {
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            _currentClickedTab.frame= newFrame;
            [CATransaction commit];
            _mouseDownPoint = mousePointInView;
        }
    }
}


- (void)mouseUp:(NSEvent *)theEvent
{
    // if they clicked the close button
    if (_currentSelectedTab.closeLayerHovered == YES)
    {
        [self removeTab:_currentSelectedTab];
        return;
    }

    if (_currentClickedTab)
    {
        // On mouse up we let the dragged tab slide to the starting or changed position.
        CGRect newFrame = _currentClickedTab.frame;
        newFrame.origin.x = _mouseDownStartingPoint.x;
        _currentClickedTab.frame = newFrame;

        if (theEvent.clickCount == 2 && [_delegate respondsToSelector:@selector(tabView:doubleClickTab:)])
        {
            [_delegate tabView:self doubleClickTab:_currentSelectedTab];
        }

        _currentClickedTab = nil;
    }

    [self refreshCloseListener];
    [self scrollToTab:_currentSelectedTab];
}



#pragma mark - Adding and Removing Tabs

- (void)addTabWithRepresentedObject:(id)representedObject
{
    [self addTabAtIndex:[self numberOfTabs] withRepresentedObject:representedObject];
}


/*
 * This redundancy seems to improve performance
 */
- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint localPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSPoint layerPoint = [self convertPointToBase:localPoint];
    [_currentSelectedTab mousemove:layerPoint];
}


/*
 * This redundancy seems to improve performance
 */
- (void)mouseExited:(NSEvent *)theEvent
{
    NSPoint localPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSPoint layerPoint = [self convertPointToBase:localPoint];
    [_currentSelectedTab mousemove:layerPoint];
}


/*
 * This redundancy seems to improve performance
 */
- (void)mouseEntered:(NSEvent *)theEvent
{
    NSPoint localPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSPoint layerPoint = [self convertPointToBase:localPoint];
    [_currentSelectedTab mousemove:layerPoint];
}


- (void)addTabAtIndex:(int)index withRepresentedObject:(id)representedObject
{
    SFDefaultTab *newtab = [[SFDefaultTab alloc] init];
    newtab.tabLabelFont = _tabLabelFont;
    newtab.tabLabelActiveColor = _tabLabelActiveColor.CGColor;
    newtab.tabLabelInactiveColor = _tabLabelInactiveColor.CGColor;

    // Passing the represented object to the tab layer.
    if ([newtab respondsToSelector:@selector(setRepresentedObject:)])
    {
        [newtab setRepresentedObject:representedObject];
    }

    // Removing animation for z-index changes.
    NSMutableDictionary *customActions = [NSMutableDictionary dictionaryWithDictionary:[newtab actions]];
    customActions[@"zPosition"] = [NSNull null];
    [newtab setActions:customActions];

    // Setting up new tab.
    [newtab setFrame:CGRectMake([self startingXOriginForTabAtIndex:index], 0, [newtab frame].size.width, [newtab frame].size.height)];
    [newtab setZPosition:(float)index * -1 ];

    if ([self numberOfTabs] > 0 && index <= [self numberOfTabs]-1)
    {
        // Getting the right tag sequence (left-to-right).
        NSArray *tabsSequence = [self tabSequenceForStartingTabIndex:index-1 endingTabIndex:[self numberOfTabs]-1 direction:YES];

        // shifting pre-existing tabs according
        for(NSNumber *n in tabsSequence)
        {
            CALayer *landingTab = [self tabAtIndex:[n intValue]];

            // Updating z-index
            if ([landingTab isEqualTo:_currentSelectedTab] == NO)
            {
                landingTab.zPosition = (float)([n intValue] + 1) * -1;
            }

            // Moving a tab.
            CGRect newFrame = landingTab.frame;
            newFrame.origin.x += [newtab frame].size.width + _tabOffset;
            landingTab.frame = newFrame;
        }
    }

    [_tabsLayer addSublayer:newtab];
    [_arrangedTabs insertObject:newtab atIndex:index];

    // Selecting it if it's the only one.
    if ([self numberOfTabs] == 1)
    {
        [self selectTab:newtab];
    }

    int offset = _tabOffset;
    if ([self numberOfTabs] == 1)
    {
        offset = _startingOffset;
    }

    // adjusting the size of the tabsLayer
    [_tabsLayer setValue:[NSNumber numberWithInt:[newtab frame].size.width + _tabsLayer.frame.size.width + offset] forKeyPath:@"frame.size.width"];

    // Notifing delegate
    if ([_delegate respondsToSelector:@selector(tabView:didAddTab:)])
    {
        [_delegate tabView:self didAddTab:newtab];
    }
}


- (void)removeTab:(CALayer *)tab
{
    int tabIndex = [self indexOfTab:tab];
    if (tabIndex != -1)
    {
        [self removeTabAtIndex:tabIndex];
    }
}


- (void)removeTabAtIndex:(int)index
{
    // Grabbing the tab.
    int indexOfInitialTab = index;
    CALayer *tab = _arrangedTabs[indexOfInitialTab];
    CGPoint startingOrigin = tab.frame.origin;
    int indexOfLandingTab = (int)([_arrangedTabs count] - 1);

    int newIndex = indexOfInitialTab; //- 1;

    // Check whether delegate allows to delete the tab
    if ([_delegate respondsToSelector:@selector(tabView:shouldRemoveTab:)])
    {
        if ([_delegate tabView:self shouldRemoveTab:tab] == NO)
        {
            return;
        }
    }

    if ([tab isEqualTo:[self lastTab]] && [tab isEqualTo:[self firstTab]] == NO)
    {
        [self selectTab:[self tabAtIndex:indexOfLandingTab - 1]];
    }
    else if ([tab isEqualTo:[self firstTab]] && [tab isEqualTo:[self lastTab]])
    {
        _currentSelectedTab = nil;
    }

    // Getting the right tag sequence (left-to-right).
    NSArray *tabsSequence = [self tabSequenceForStartingTabIndex:indexOfInitialTab endingTabIndex:indexOfLandingTab direction:YES];

    // Sliding all right tabs to the left.
    for (NSNumber *n in tabsSequence)
    {
        CALayer *landingTab = [self tabAtIndex:[n intValue]];//[arrangedTabs objectAtIndex:[n intValue]];

        // If the deleted tag was the selected one we'll switch selection on the successive.
        if ([tab isEqualTo:_currentSelectedTab])
        {
            [self selectTab:landingTab];
        }
        // Adjusting the zPosition of moved tab (only if it's not selected).
        else if ([landingTab isNotEqualTo:_currentSelectedTab])
        {
            ++newIndex;
            landingTab.zPosition = (float)newIndex * -1;
        }

        // Moving a tab.
        CGRect newFrame = CGRectMake(startingOrigin.x, startingOrigin.y, landingTab.frame.size.width , landingTab.frame.size.height);
        landingTab.frame = newFrame;
        startingOrigin.x += newFrame.size.width + _tabOffset;
    }

    // Removing the frame from the view layer without animating.
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [tab removeFromSuperlayer];
    [CATransaction commit];


    int offset = _tabOffset;
    if ([self numberOfTabs] == 1)
    {
        offset = _startingOffset;
    }

    // adjusting the size of the tabsLayer
    [_tabsLayer setValue:[NSNumber numberWithInt:_tabsLayer.frame.size.width - ([tab frame].size.width + offset)] forKeyPath:@"frame.size.width"];

    if ([_delegate respondsToSelector:@selector(tabView:didRemovedTab:)])
    {
        [_delegate tabView:self didRemovedTab:tab];
    }

    // Removing tab from the arranged tags.
    [_arrangedTabs removeObject:tab];

    [self adjustTabLayerScrollAnimated:YES];
}


- (void)removeAllTabs
{
    while (self.numberOfTabs > 0)
    {
        [self removeTabAtIndex:0];
    }
}


#pragma mark - Accessing Tabs

- (int)indexOfTab:(CALayer *)tab
{
    return (int)[_arrangedTabs indexOfObject:tab];
}


- (int)numberOfTabs
{
    return (int)[_arrangedTabs count];
}


- (CALayer *)tabAtIndex:(int)index
{
    return _arrangedTabs[index];
}


- (NSArray *)arrangedTabs
{
    return _arrangedTabs;
}


- (CALayer *)firstTab
{
    if ([_arrangedTabs count] == 0)
    {
        return NULL;
    }
    return _arrangedTabs[0];
}


- (CALayer *)lastTab
{
    return [_arrangedTabs lastObject];
}



#pragma mark - Selecting a Tab

- (void)selectTab:(SFDefaultTab *)tab
{
    if ([_arrangedTabs containsObject:tab] == NO)
    {
        return;
    }

    if ([_delegate respondsToSelector:@selector(tabView:willSelectTab:)])
    {
        [_delegate tabView:self willSelectTab:tab];
    }

    if (_currentSelectedTab)
    {
        _currentSelectedTab.zPosition = ([self indexOfTab:_currentSelectedTab] * -1.0);
        if ([_currentSelectedTab respondsToSelector:@selector(setSelected:)])
        {
            [_currentSelectedTab setSelected:NO];
        }
        _currentSelectedTab = nil;
    }

    _currentSelectedTab = tab;

    [self refreshCloseListener];

    _currentSelectedTab.zPosition = 1000;

    if ([_currentSelectedTab respondsToSelector:@selector(setSelected:)])
    {
        [_currentSelectedTab setSelected:YES];
    }

    if ([_delegate respondsToSelector:@selector(tabView:didSelectTab:)])
    {
        [_delegate tabView:self didSelectTab:tab];
    }

    [self scrollToTab:_currentSelectedTab];
}


- (void)refreshCloseListener
{
    // Setting up tracking area
    [self removeTrackingArea:_area];
    _area = [[NSTrackingArea alloc] initWithRect:_currentSelectedTab.frame options:(NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp) owner:self userInfo:nil];
    [self addTrackingArea:_area];
}


- (void)selectTabAtIndex:(unsigned int)index
{
    [self selectTab:[self tabAtIndex:index]];
}


- (void)selectFirstTab:(id)sender
{
    [self selectTab:[self firstTab]];
}


- (void)selectLastTab:(id)sender
{
    [self selectTab:[self lastTab]];
}


- (void)selectNextTab:(id)sender
{
    unsigned int currentTabIndex = [self indexOfTab:[self selectedTab]];
    int nextIndex = currentTabIndex + 1;
    if (currentTabIndex == [self numberOfTabs] -1)
    {
        nextIndex = 0;
    }

    [self selectTabAtIndex:nextIndex];
}


- (void)selectPreviousTab:(id)sender
{
    unsigned int currentTabIndex = [self indexOfTab:[self selectedTab]];
    int prevIndex = currentTabIndex - 1;
    if (currentTabIndex == 0)
    {
        prevIndex = [self numberOfTabs] -1;
    }
    [self selectTabAtIndex:prevIndex];
}


- (CALayer *)selectedTab
{
    return _currentSelectedTab;
}



#pragma mark - Scrolling

- (void)scrollToTab:(CALayer *)tab
{
    [self scrollToTab:tab animated:YES];
}


- (void)scrollToTab:(CALayer *)tab animated:(BOOL)animated
{
    NSMutableDictionary *actions = [NSMutableDictionary dictionaryWithDictionary:[_scrollLayer actions]];
    [actions removeObjectForKey:@"position"];
    [actions removeObjectForKey:@"bounds"];

    float duration = 0.0f;
    if (animated)
    {
        duration = 0.4f;
    }

    [CATransaction begin];
    [CATransaction setValue:@(duration) forKey:@"animationDuration"];

    [_scrollLayer setActions:actions];

    CGRect newFrame = tab.frame;
    if ([tab isNotEqualTo:[self firstTab]] /*&& [tab isNotEqualTo:[self lastTab]]*/)
    {
        newFrame.origin.x -= round(newFrame.size.width / 2.0);
        newFrame.size.width += newFrame.size.width;
    }
    else if ([tab isEqualTo:[self firstTab]])
    {
        newFrame.origin.x -= _startingOffset;
    }
    [_tabsLayer scrollRectToVisible:newFrame];

    [CATransaction commit];

    actions[@"position"] = [NSNull null];
    actions[@"bounds"] = [NSNull null];
    [_scrollLayer setActions:actions];
}


- (void)scrollToPoint:(CGPoint)point animated:(BOOL)animated
{
    NSMutableDictionary *actions=[NSMutableDictionary dictionaryWithDictionary:[_scrollLayer actions]];
    [actions removeObjectForKey:@"position"];
    [actions removeObjectForKey:@"bounds"];

    float duration = 0.0f;
    if (animated)
    {
        duration = 0.4f;
    }

    [CATransaction begin];
    [CATransaction setValue:@(duration) forKey:@"animationDuration"];

    [_scrollLayer setActions:actions];
    [_tabsLayer scrollPoint:point];

    [CATransaction commit];

    actions[@"position"] = [NSNull null];
    actions[@"bounds"] = [NSNull null];
    [_scrollLayer setActions:actions];
}



#pragma mark - Tab Handling

- (void)rearrangeInitialTab:(CALayer *)initialTab toLandingTab:(CALayer *)landingTab withCurrentPoint:(CGPoint)currentPoint direction:(BOOL)direction
{
    int indexOfInitialTab = [self indexOfTab:initialTab];
    int indexOfLandingTab = [self indexOfTab:landingTab];

    // Getting the right tag sequence (left-to-right or right-to-left)
    NSArray *tabsSequence = [self tabSequenceForStartingTabIndex:indexOfInitialTab endingTabIndex:indexOfLandingTab direction:direction];

    for (NSNumber *n in tabsSequence)
    {
        landingTab = [self tabAtIndex:[n intValue]];

        int newIndex = 0;
        int landingOriginOffset = 0;
        int initialOriginOffset = 0;

        // We are moving left to right, so the origin of the selected tab should be updated.
        if (direction && currentPoint.x >= landingTab.position.x)
        {
            newIndex = indexOfInitialTab + 1;

            landingOriginOffset = landingTab.frame.size.width - initialTab.frame.size.width;
            [self scrollToTab:_currentSelectedTab];
        }

        // Moving right to left, the origin of the moved (not selected) tab should be updated.
        else if (direction == NO && currentPoint.x < landingTab.position.x )
        {
            newIndex = indexOfInitialTab - 1;

            initialOriginOffset = landingTab.frame.size.width - initialTab.frame.size.width;
            [self scrollToTab:_currentSelectedTab];

        }
        else
        {
            continue;
        }

        // Swapping indexes of initial tab and landing tab
        [_arrangedTabs removeObjectAtIndex:indexOfInitialTab];
        [_arrangedTabs insertObject:initialTab atIndex:newIndex];

        landingTab.zPosition = indexOfInitialTab * -1;
        indexOfInitialTab = newIndex;

        // If the tab are of different size we need to adjust the new origin point.
        CGPoint landingOrigin = landingTab.frame.origin;
        landingOrigin.x += landingOriginOffset;

        CGRect newFrame = CGRectMake(_mouseDownStartingPoint.x - initialOriginOffset, _mouseDownStartingPoint.y, landingTab.frame.size.width, landingTab.frame.size.height);

        landingTab.frame = newFrame;
        _mouseDownStartingPoint = landingOrigin;

        if ([self.delegate respondsToSelector:@selector(tabView:didArrangeTab:fromIndex:toIndex:)])
        {
            [self.delegate tabView:self didArrangeTab:initialTab fromIndex:indexOfInitialTab toIndex:newIndex];
        }
    }
}



#pragma mark - Utility methods

/* Return a correctly ordered (depepending on direction) tab indexes array */
- (NSArray *)tabSequenceForStartingTabIndex:(int)startingIndex endingTabIndex:(int)endingIndex direction:(BOOL)direction
{
    NSMutableArray *tagsSequence = [NSMutableArray array];

    for (int i = MIN(startingIndex, endingIndex); i<=MAX(startingIndex, endingIndex); i++)
    {
        if (i == startingIndex)
        {
            continue;
        }
        else if (direction)
        {
            [tagsSequence addObject:@(i)];
        }
        else
        {
            [tagsSequence insertObject:@(i) atIndex:0];
        }
    }
    return tagsSequence;
}


/* Return the initial x coordinate for a new tab */
- (int)startingXOriginForTabAtIndex:(int)index
{
    if (index == 0)
    {
        return _startingOffset;
    }
    else
    {
        return [[self tabAtIndex:index-1] frame].origin.x + [[self tabAtIndex:index-1] frame].size.width + _tabOffset;
    }
}


- (NSPoint)deltaFromStartingPoint:(NSPoint)startingPoint endPoint:(NSPoint)endPoint
{
    return NSMakePoint(endPoint.x - startingPoint.x, endPoint.y - startingPoint.y);
}


/* basic animation for moving tabs */
- (CABasicAnimation *)tabMovingAnimation
{
    CABasicAnimation *slideAnimation = [CABasicAnimation animation];
    slideAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    return slideAnimation;
}

@end
