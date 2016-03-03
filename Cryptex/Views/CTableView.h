//
//  CTableView.h
//  Cryptex
//
//  Created by Gints Murans on 30/10/14.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CTableViewDelegate <NSObject>
@optional
- (void)CTableTextDidEndEditing:(NSString *)string;
@end


@interface CTableView : NSTableView
@property (nonatomic, assign) id<CTableViewDelegate> cDelegate;
@end
