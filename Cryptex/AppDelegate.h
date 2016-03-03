//
//  AppDelegate.h
//  Cryptex
//
//  Created by Gints Murans on 19/08/2014.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "INAppStoreWindow.h"
#import "CTextView.h"
#import "CTableView.h"

// Import swift
#import "Cryptex-Swift.h"


typedef void(^SaveCallbackBlock)();


@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, CTableViewDelegate, NSTextViewDelegate>
{
    // Some instance variables
    BOOL _closing;
    SaveCallbackBlock _closeCallbackBlock;

    NSURL *_lastFilename, *_lockedFilename, *_exportURL;
    NSString *_password;

    // Decrypted data
    NSMutableDictionary *_decryptedData;
    NSUInteger _currentSheetNumber;
    NSMutableDictionary *_currentSheet;

    // Tabs and text
    IBOutlet CSplitView *_splitView;
    IBOutlet CTextView *_textView;
    IBOutlet CTableView *_tableView;

    // Lock screen
    IBOutlet NSView *_lockScreen;
    IBOutlet NSTextField *_lockFilename;
    IBOutlet NSSecureTextField *_lockPasswordField;

    // Other
    IBOutlet NSMenu *_exportMenu;
    NSMenu *_exportMenuForTextView;
}

@property (assign) IBOutlet INAppStoreWindow *window;
@property (assign) IBOutlet NSView *mainView;


- (IBAction)newDocument:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveAsDocument:(id)sender;
- (IBAction)closeDocument:(id)sender;
- (IBAction)lockDocument:(id)sender;
- (IBAction)unlockDocument:(id)sender;
- (IBAction)printDocument:(id)sender;

- (IBAction)exportToMarkdown:(id)sender;
- (IBAction)exportToHtml:(id)sender;
- (IBAction)exportToPdf:(id)sender;
- (IBAction)exportToCX:(id)sender;

- (IBAction)newSheet:(id)sender;
- (IBAction)nextSheet:(id)sender;
- (IBAction)previousSheet:(id)sender;
- (IBAction)deleteSheet:(id)sender;

- (IBAction)shiftRight:(id)sender;
- (IBAction)shiftLeft:(id)sender;

@end
