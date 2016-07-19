//
//  AppDelegate.m
//  Cryptex
//
//  Created by Gints Murans on 19/08/2014.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import "AppDelegate.h"
#import <PasswordManager/PasswordManager.h>
#import "BFImage.h"
#import "GZIP.h"
#import "HGMarkdownHighlighter.h"
#import <WebKit/WebKit.h>

#ifdef ADHOC
#import <Sparkle/SUUpdater.h>
#endif


#define BasicTableViewDragAndDropDataType @"BasicTableViewDragAndDropDataType"

@implementation AppDelegate


#ifdef ADHOC
- (void)checkForUpdate:(NSMenuItem *)sender
{
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}
#endif


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
#ifdef ADHOC
    // Insert Check For Updates menu
    NSMenu *mainMenu = [NSApp mainMenu];
    NSMenu *appMenu = [[mainMenu itemAtIndex:0] submenu];
    NSMenuItem *uploadMenu = [[NSMenuItem alloc] init];
    [uploadMenu setTitle:NSLocalizedString(@"Check for Updates", nil)];
    [uploadMenu setTarget:self];
    [uploadMenu setAction:@selector(checkForUpdate:)];
    [appMenu insertItem:uploadMenu atIndex:1];

    NSMenuItem *separator = [NSMenuItem separatorItem];
    [appMenu insertItem:separator atIndex:1];
#endif

    // Init defaults
    _closing = NO;
    _currentSheetNumber = -1;
    _lastFilename = [[NSUserDefaults standardUserDefaults] URLForKey:@"LastFilename"];

    // Setup window
    self.window.showsTitle = YES;
    self.window.verticallyCenterTitle = YES;
    self.window.titleBarHeight = 38.0;
    self.window.hideTitleBarInFullScreen = YES;
    self.window.baselineSeparatorColor = [NSColor colorWithR:190.0 g:190.0 b:190.0 alpha:190.0];
    self.window.centerTrafficLightButtons = YES;
    self.window.trafficLightButtonsLeftMargin = 12.0;

    // Add lockscreen for better visual look on startup
    [_splitView setHidden:YES];

    _lockScreen.frame = _mainView.frame;
    [_lockScreen setHidden:YES];
    [_mainView addSubview:_lockScreen];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Set global print parameters
    NSPrintInfo *printInfo = [[NSPrintInfo alloc] init];
    printInfo.topMargin = 56.692944;
    printInfo.leftMargin = 56.692944;
    printInfo.bottomMargin = 56.692944;
    printInfo.leftMargin = 56.692944;
    printInfo.horizontallyCentered = NO;
    printInfo.verticallyCentered = NO;
    printInfo.verticalPagination = NSAutoPagination;
    printInfo.horizontalPagination = NSAutoPagination;

    [NSPrintInfo setSharedPrintInfo:printInfo];

    // Set delegates
    self.window.delegate = self;
    _tableView.cDelegate = self;

    // Register for file drag and drop
    [_tableView registerForDraggedTypes:[NSArray arrayWithObject:BasicTableViewDragAndDropDataType]];

    // Listen for sleep notifications
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(receiveSleepNote:)
                                                               name:NSWorkspaceWillSleepNotification object:NULL];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(receiveSleepNote:)
                                                               name:NSWorkspaceScreensDidSleepNotification object:NULL];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(receiveSleepNote:)
                                                               name:NSWorkspaceSessionDidResignActiveNotification object:NULL];


    // Set textview delegate
    _exportMenuForTextView = [_exportMenu copy];
    for (NSMenuItem *item in _exportMenuForTextView.itemArray) {
        item.tag = 9;
    }

    // Finally open last document or create a new one
    if (_lockedFilename == nil) // Because openFile is run before applicationDidFinishLaunching
    {
        if (_lastFilename != nil)
        {
            // At applicationWillFinishLaunching file is, for some reason, not readable, so we do this here
            if ([[NSFileManager defaultManager] isReadableFileAtPath:[_lastFilename path]])
            {
                [self openFile:_lastFilename];
            }
            else
            {
                _lastFilename = nil;
                [self newDocument:nil];
            }
        }
        else
        {
            [self newDocument:nil];
        }
    }
}


- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    if ([filename hasSuffix:@".cx"] == NO)
    {
        return NO;
    }

    [self openFile:[NSURL fileURLWithPath:filename]];
    return YES;
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (self.window.isDocumentEdited == YES)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert addButtonWithTitle:@"Cancel"];

        [alert setMessageText:@"Document not saved! Do you want to save it first?"];
        [alert setAlertStyle:NSWarningAlertStyle];

        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn)
            {
                __block AppDelegate *_self = self;
                _closeCallbackBlock = ^(){
                    if (_self.window.isDocumentEdited == NO)
                    {
                        [_self closeFile];
                        [[NSApplication sharedApplication] terminate:_self];
                    }
                };
                [self saveDocument:nil];
            }
            else if (returnCode == NSAlertSecondButtonReturn)
            {
                [self closeFile];
                [[NSApplication sharedApplication] terminate:self];
            }
        }];
        return NSTerminateCancel;
    }

    // Close the file if its open
    [self closeFile];

    // Terminate the process
    return NSTerminateNow;
}


#pragma mark - NSWorkspace notifications

- (void)receiveSleepNote:(NSNotification *)note
{
    if (_decryptedData != nil && _password != nil)
    {
        [self lockFileWithFilename:_lastFilename];
    }
}


#pragma mark - Helpers

- (void)showMsg:(NSString *)msg withInfo:(NSString *)info withAlertStyle:(NSAlertStyle)alertStyle
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];

    [alert setMessageText:msg];
    [alert setInformativeText:info];
    [alert setAlertStyle:alertStyle];

    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}


- (void)updateCurrentTitles
{
    NSString *filename;
    if (_lockedFilename != nil)
    {
        filename = [[_lockedFilename path] lastPathComponent];
    }
    else if (_lastFilename != nil)
    {
        filename = [[_lastFilename path] lastPathComponent];
    }
    else
    {
        filename = @"Untitled.cx";
    }
    [self.window setTitle:filename];
}


- (void)removeLockscreen
{
    if (_lockScreen.hidden == NO)
    {
        [_lockScreen setHidden:YES];
        _lockPasswordField.stringValue = @"";
        _lockedFilename = nil;
    }

    if (_splitView.hidden == YES)
    {
        [_splitView setHidden:NO];
    }
}


- (void)openFile:(NSURL *)filename
{
    if (_decryptedData != nil)
    {
        if (self.window.isDocumentEdited == YES)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];

            [alert setMessageText:@"Document not saved! Do you want to save it first?"];
            [alert setAlertStyle:NSWarningAlertStyle];

            [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSAlertFirstButtonReturn)
                {
                    __block AppDelegate *_self = self;
                    _closeCallbackBlock = ^(){
                        if (_self.window.isDocumentEdited == NO)
                        {
                            [_self closeFile];
                            [_self openFile:filename];
                        }
                    };
                    [self saveDocument:nil];
                }
                else if (returnCode == NSAlertSecondButtonReturn)
                {
                    [self closeFile];
                    [self openFile:filename];
                }
            }];
            return;
        }

        // Close the file if its open
        [self closeFile];
    }


    NSLog(@"Open: %@", filename);

    if ([[NSFileManager defaultManager] isReadableFileAtPath:[filename path]] == NO)
    {
        [self showMsg:@"Error reading the file!" withInfo:@"Make sure you have access to the file." withAlertStyle:NSCriticalAlertStyle];
        return;
    }

    // Try to load encrypted data
    NSData *data = [NSData dataWithContentsOfURL:filename];
    if (data == nil)
    {
        [self showMsg:@"Error reading the file!" withInfo:@"Make sure you have access to the file." withAlertStyle:NSCriticalAlertStyle];
        return;
    }

    // Check for password
    if (_password == nil)
    {
        [self lockFileWithFilename:filename];
        [self.window makeKeyAndOrderFront:nil];
        return;
    }

    // Try to decrypt data
    data = [PasswordManager decryptData:data withPassword:_password error:nil];
    data = [data gunzippedData];
    if (data == nil)
    {
        [self showMsg:@"Error decrypting the file!" withInfo:@"Wrong password, I guess!" withAlertStyle:NSCriticalAlertStyle];
        [self.window makeKeyAndOrderFront:nil];
        [self.window makeFirstResponder:_lockPasswordField];
        return;
    }

    NSMutableDictionary *tmp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if (tmp == nil)
    {
        [self showMsg:@"Error decrypting the file!" withInfo:@"Wrong password, I guess!" withAlertStyle:NSCriticalAlertStyle];
        [self.window makeKeyAndOrderFront:nil];
        [self.window makeFirstResponder:_lockPasswordField];
        data = nil;
        return;
    }

    // Remove lockscreen
    [self removeLockscreen];

    // Load new ones
    _decryptedData = tmp;
    _lastFilename = filename;
    [self updateCurrentTitles];

    // Save some defaults
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:_lastFilename];
    [[NSUserDefaults standardUserDefaults] setURL:_lastFilename forKey:@"LastFilename"];

    // Load sheets
    NSArray *items = [_decryptedData objectForKey:@"items"];
    NSNumber *selSheet = [_decryptedData objectForKey:@"sel_sheet"];

    if (items.count > 0)
    {
        int selectedSheet = (selSheet != nil && [selSheet integerValue] <= items.count ? [selSheet intValue] : 0);
        [_tableView reloadData];
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedSheet] byExtendingSelection:NO];
    }
    else
    {
        [self newSheet:nil];
    }

    // Make window active
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:_textView];
}


- (void)closeFile
{
    _closing = YES;

    _lockedFilename = nil;
    _lastFilename = nil;
    _currentSheet = nil;
    _currentSheetNumber = -1;
    _decryptedData = nil;

    [_tableView reloadData];
    _textView.string = @"";
    [_textView.hl clearHighlighting];

    _password = nil;
    _closing = NO;

    [self.window setDocumentEdited:NO];

    // Delete undo data
    [_textView.undoManager removeAllActions];
}


- (void)lockFileWithFilename:(NSURL *)filename
{
    if (_lockScreen.hidden == NO && [_lockedFilename isEqualTo:filename])
    {
        return;
    }

    // Save ir first
    if (_decryptedData != nil)
    {
        if (filename == nil)
        {
            [self saveDocument:nil];
            return;
        }
        [self saveDocument:nil];

        // Clear the memory
        [self closeFile];
    }

    // Save reference to the filename that we are locking up
    _lastFilename = nil;
    _lockedFilename = filename;
    _lockFilename.stringValue = [NSString stringWithFormat:@"Open \"%@\"", [[filename path] lastPathComponent]];
    [self updateCurrentTitles];

    // Show lockscreen
    [_splitView setHidden:YES];
    [_lockScreen setHidden:NO];

    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:_lockPasswordField];
}


- (void)unlockDocument:(id)sender
{
    _password = [_lockPasswordField.stringValue copy];
    [self openFile:_lockedFilename];
}


- (void)loadSheet:(NSUInteger)sheetNumber
{
    if ((int)sheetNumber < 0 || sheetNumber >= [[_decryptedData objectForKey:@"items"] count])
    {
        return;
    }

    // Find current sheet
    _currentSheetNumber = sheetNumber;
    _currentSheet = [[_decryptedData objectForKey:@"items"] objectAtIndex:_currentSheetNumber];
    NSString *tmp = [_currentSheet objectForKey:@"range"]; // Before updating textview string

    // Set textview
    _textView.string = [[_currentSheet objectForKey:@"data"] copy];
    _textView.selectedRange = (tmp == nil ? NSMakeRange(0, 0) : NSRangeFromString(tmp));
    [_textView.hl parseAndHighlightAll];

    // Scroll to selection
    if (tmp != nil)
    {
        [_textView scrollRangeToVisible:NSRangeFromString(tmp)];
    }

    // Delete undo data
    [_textView.undoManager removeAllActions];
}


- (NSString *)convertStringToHTML:(NSString *)str
{
    NSTask *task = [[NSTask alloc] init];

    NSString *perlFile = [[NSBundle mainBundle] pathForResource:@"Markdown" ofType:@"pl"];
    [task setLaunchPath:perlFile];

    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:[NSPipe pipe]];

    NSFileHandle *writingHandle = [[task standardInput] fileHandleForWriting];
    [writingHandle writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    [writingHandle closeFile];

    [task launch];
    [task waitUntilExit];

    NSData *outputData = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    NSString *resultString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    return resultString;
}



#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
    [self closeDocument:sender];
    return NO;
}



#pragma mark - IBActions

- (IBAction)newDocument:(id)sender
{
    if (self.window.isDocumentEdited == YES)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert addButtonWithTitle:@"Cancel"];

        [alert setMessageText:@"Document not saved! Do you want to save it first?"];
        [alert setAlertStyle:NSWarningAlertStyle];

        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn)
            {
                __block AppDelegate *_self = self;
                _closeCallbackBlock = ^(){
                    if (_self.window.isDocumentEdited == NO)
                    {
                        [_self closeFile];
                        [_self newDocument:sender];
                    }
                };
                [self saveDocument:nil];
            }
            else if (returnCode == NSAlertSecondButtonReturn)
            {
                [self closeFile];
                [self newDocument:sender];
            }
        }];
        return;
    }

    // Close the file if its open
    [self closeFile];

    // Remove lockscreen if any
    [self removeLockscreen];

    // Create new dictionary object
    _decryptedData = [NSMutableDictionary dictionary];
    [_decryptedData setObject:@"v001" forKey:@"version"];
    [_decryptedData setObject:@(0) forKey:@"sel_sheet"];

    // Fill in help data
    BOOL hasRun = ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasRun"] == YES);
    if (hasRun == NO)
    {
        NSString *pathToHelpFile = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"md"];
        NSString *helpData = [NSString stringWithContentsOfFile:pathToHelpFile encoding:NSUTF8StringEncoding error:nil];

        [_decryptedData setObject:[NSMutableArray arrayWithObject:[@{

                                                                     @"title": @"Cryptex",
                                                                     @"data": helpData,
                                                                     @"range": NSStringFromRange(NSMakeRange(0, 0))

                                                                    } mutableCopy]] forKey:@"items"];

        // Save that we have run for the first time, no need to show help anymore
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasRun"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        [_decryptedData setObject:[NSMutableArray arrayWithObject:[@{

                                                                     @"title": @"Untitled",
                                                                     @"data": @"",
                                                                     @"range": NSStringFromRange(NSMakeRange(0, 0))

                                                                     } mutableCopy]] forKey:@"items"];
    }

    // Add Tab
    [_tableView reloadData];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];

    // Set not-edited
    [self.window setDocumentEdited:NO];

    // Make window active
    [self updateCurrentTitles];
    [self.window makeKeyAndOrderFront:sender];
    [self.window makeFirstResponder:_textView];
}


- (void)saveAsDocument:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"cx"]];
    savePanel.treatsFilePackagesAsDirectories = YES;
    if (_lastFilename != nil)
    {
        [savePanel setNameFieldStringValue:[[_lastFilename absoluteString] lastPathComponent]];
    }

    // Create an accessory view for password fields
    NSView *aView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 370, 150)];
    savePanel.accessoryView = aView;

    // Add password fields
    NSTextField *passwordFieldLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, aView.frame.size.height - 32, 200, 25)];
    passwordFieldLabel.stringValue = @"Password:";
    passwordFieldLabel.font = [NSFont fontWithName:@"Helvetica Neue" size:13.0];
    [passwordFieldLabel setBezeled:NO];
    [passwordFieldLabel setDrawsBackground:NO];
    [passwordFieldLabel setEditable:NO];
    [passwordFieldLabel setSelectable:NO];
    [passwordFieldLabel sizeToFit];
    [aView addSubview:passwordFieldLabel];


    NSSecureTextField *passwordField1 = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25)];
    if ([passwordField1 respondsToSelector:@selector(setPlaceholderString:)])
    {
        passwordField1.placeholderString = @"Enter your password";
    }
    else
    {
        [passwordField1.cell setPlaceholderString:@"Enter your password"];
    }
//    passwordField1.alignment = NSCenterTextAlignment;
    [aView addSubview:passwordField1];

    NSSecureTextField *passwordField2 = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(passwordField1.frame.origin.x, passwordField1.frame.origin.y - passwordField1.frame.size.height - 5.0, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25)];
    if ([passwordField2 respondsToSelector:@selector(setPlaceholderString:)])
    {
        passwordField2.placeholderString = @"Repeat your password";
    }
    else
    {
        [passwordField2.cell setPlaceholderString:@"Enter your password"];
    }
//    passwordField2.alignment = NSCenterTextAlignment;
    [aView addSubview:passwordField2];

    // Add description field
    NSTextField *descriptionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, aView.frame.size.width, 75)];
    descriptionLabel.stringValue = @"Choose your password wisely. We recomend using passwords made of multiple words and spaces between them making a sentence that makes sense only to you. For example: Big brown cow runs up in space 4 times in a row.";
    descriptionLabel.font = [NSFont fontWithName:@"Helvetica Neue" size:11.0];
    [descriptionLabel.cell setWraps:YES];
    [descriptionLabel setBezeled:NO];
    [descriptionLabel setDrawsBackground:NO];
    [descriptionLabel setEditable:NO];
    [descriptionLabel setSelectable:NO];
    [aView addSubview:descriptionLabel];


    // Show the panel
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
        {
            [savePanel orderOut:self];

            if ([passwordField1.stringValue isEqualToString:passwordField2.stringValue] == NO)
            {
                [self showMsg:@"Error!" withInfo:@"Passwords does not match." withAlertStyle:NSCriticalAlertStyle];
                return;
            }

            _password = passwordField1.stringValue;
            _lastFilename = [savePanel URL];
            [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:_lastFilename];
            [[NSUserDefaults standardUserDefaults] setURL:_lastFilename forKey:@"LastFilename"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self saveDocument:sender];
            [self updateCurrentTitles];

            // Warn about the password
            if (passwordField1.stringValue.length < 1)
            {
                [self showMsg:@"Warning!" withInfo:@"It is generally safer to provide at least some password than no password at all." withAlertStyle:NSCriticalAlertStyle];
            }
        }
    }];
}


- (void)saveDocument:(id)sender
{
    if (_lastFilename == nil)
    {
        [self saveAsDocument:sender];
        return;
    }

    NSLog(@"Save to: %@", _lastFilename);

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_decryptedData options:0 error:nil];
    NSData *finalFile = [jsonData gzippedData];
    finalFile = [PasswordManager encryptData:finalFile withPassword:_password error:nil];
    BOOL success = [finalFile writeToURL:_lastFilename atomically:YES];

    if (success == NO)
    {
        [self showMsg:@"Error writing file!" withInfo:@"Make sure you have access to the folder." withAlertStyle:NSCriticalAlertStyle];
    }
    else
    {
        [self.window setDocumentEdited:NO];

        if (_closeCallbackBlock != nil)
        {
            _closeCallbackBlock();
            _closeCallbackBlock = nil;
        }
    }
}


- (void)openDocument:(id)sender
{
    // If window is closed create new document first to avoid unexpected behaviour
    if (self.window.isVisible == NO && _lastFilename == nil)
    {
        [self newDocument:sender];
    }

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:@[@"cx"]];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
        {
            [openPanel orderOut:self];
            [self openFile:[openPanel URL]];
        }
    }];
}


- (void)closeDocument:(id)sender
{
    if (self.window.isDocumentEdited == YES)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert addButtonWithTitle:@"Cancel"];

        [alert setMessageText:@"Document not saved! Do you want to save it first?"];
        [alert setAlertStyle:NSWarningAlertStyle];

        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn)
            {
                __block AppDelegate *_self = self;
                _closeCallbackBlock = ^(){
                    if (_self.window.isDocumentEdited == NO)
                    {
                        [_self closeFile];
                        [_self.window close];
                    }
                };
                [self saveDocument:nil];
            }
            else if (returnCode == NSAlertSecondButtonReturn)
            {
                [self closeFile];
                [self.window close];
            }
        }];
        return;
    }

    // Close the file
    [self closeFile];

    // And close the window
    [self.window close];
}


- (void)lockDocument:(id)sender
{
    [self lockFileWithFilename:_lastFilename];
}


- (void)printDocument:(id)sender
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    NSTextView *printView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin, _textView.frame.size.height)];
    [printView setString:_textView.string];

    // Calculate real height of the text view
    (void)[[printView layoutManager] glyphRangeForTextContainer:[printView textContainer]];
    float containerHeight = [[printView layoutManager] usedRectForTextContainer:[printView textContainer]].size.height;
    CGRect frame = printView.frame;
    frame.size.height = containerHeight;
    printView.frame = frame;

    // Highlighter
    HGMarkdownHighlighter *hl = [[HGMarkdownHighlighter alloc] initWithTextView:printView];

    NSString *styleFilePath = [[NSBundle mainBundle] pathForResource:@"Cryptex-print" ofType:@"style"];
    NSString *styleContents = [NSString stringWithContentsOfFile:styleFilePath encoding:NSUTF8StringEncoding error:NULL];
    [hl applyStylesFromStylesheet:styleContents withErrorHandler:^(NSArray *errorMessages) {
        NSMutableString *errorsInfo = [NSMutableString string];
        for (NSString *str in errorMessages)
        {
            [errorsInfo appendString:@"• "];
            [errorsInfo appendString:str];
            [errorsInfo appendString:@"\n"];
        }
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"There were some errors when parsing the stylesheet:"
                                         defaultButton:@"Ok"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", errorsInfo];
        [alert runModal];
    }];
    hl.parseAndHighlightCallback = ^(){
        [[NSPrintOperation printOperationWithView:printView printInfo:printInfo] runOperationModalForWindow:self.window delegate:nil didRunSelector:nil contextInfo:nil];
    };
    [hl activate];
    [hl parseAndHighlightNow];
}


- (void)exportToMarkdown:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"md"]];
    savePanel.treatsFilePackagesAsDirectories = YES;
    if (_lastFilename != nil)
    {
        [savePanel setNameFieldStringValue:[[[_lastFilename absoluteString] lastPathComponent] stringByDeletingPathExtension]];
    }
    
    // Create an accessory view
    NSView *aView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 370, 45)];
    savePanel.accessoryView = aView;
    
    NSTextField *passwordFieldLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, aView.frame.size.height - 30, 200, 25)];
    passwordFieldLabel.stringValue = @"Export:";
    passwordFieldLabel.font = [NSFont fontWithName:@"Helvetica Neue" size:13.0];
    [passwordFieldLabel setBezeled:NO];
    [passwordFieldLabel setDrawsBackground:NO];
    [passwordFieldLabel setEditable:NO];
    [passwordFieldLabel setSelectable:NO];
    [passwordFieldLabel sizeToFit];
    [aView addSubview:passwordFieldLabel];
    
    NSComboBox *picker = [[NSComboBox alloc] initWithFrame:NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25)];
    [picker setEditable:NO];
    
    [picker addItemsWithObjectValues:@[@"Current Sheet", @"Current Selection"]];
    [picker selectItemAtIndex:([sender tag] == 9 ? 1 : 0)];
    [aView addSubview:picker];
    

    // Show the panel
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
        {
            [savePanel orderOut:self];

            NSData *dataToSave = nil;
            if (picker.indexOfSelectedItem == 0)
            {
                dataToSave = [_textView.string dataUsingEncoding:NSUTF8StringEncoding];
            }
            else
            {
                dataToSave = [[_textView.string substringWithRange:[_textView selectedRange]] dataUsingEncoding:NSUTF8StringEncoding];
            }

            NSURL *filename = [savePanel URL];
            [dataToSave writeToURL:filename atomically:YES];
        }
    }];
}


- (void)exportToHtml:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"html"]];
    savePanel.treatsFilePackagesAsDirectories = YES;
    if (_lastFilename != nil)
    {
        [savePanel setNameFieldStringValue:[[[_lastFilename absoluteString] lastPathComponent] stringByDeletingPathExtension]];
    }
    
    // Create an accessory view
    NSView *aView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 370, 45)];
    savePanel.accessoryView = aView;
    
    NSTextField *passwordFieldLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, aView.frame.size.height - 30, 200, 25)];
    passwordFieldLabel.stringValue = @"Export:";
    passwordFieldLabel.font = [NSFont fontWithName:@"Helvetica Neue" size:13.0];
    [passwordFieldLabel setBezeled:NO];
    [passwordFieldLabel setDrawsBackground:NO];
    [passwordFieldLabel setEditable:NO];
    [passwordFieldLabel setSelectable:NO];
    [passwordFieldLabel sizeToFit];
    [aView addSubview:passwordFieldLabel];
    
    NSComboBox *picker = [[NSComboBox alloc] initWithFrame:NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25)];
    [picker setEditable:NO];
    
    [picker addItemsWithObjectValues:@[@"Current Sheet", @"Current Selection"]];
    [picker selectItemAtIndex:([sender tag] == 9 ? 1 : 0)];
    [aView addSubview:picker];
    
    
    // Show the panel
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
        {
            [savePanel orderOut:self];

            NSString *dataToSave = nil;
            if (picker.indexOfSelectedItem == 0)
            {
                dataToSave = _textView.string;
            }
            else
            {
                dataToSave = [_textView.string substringWithRange:[_textView selectedRange]];
            }

            NSString *baseContextFile = [[NSBundle mainBundle] pathForResource:@"HTMLTemplate" ofType:@"html"];
            NSString *baseHTMLString = [NSString stringWithContentsOfFile:baseContextFile encoding:NSUTF8StringEncoding error:NULL];
            NSString *newString = [self convertStringToHTML:dataToSave];
            NSString *saveString = [NSString stringWithFormat:baseHTMLString, [[_lastFilename path] lastPathComponent], newString];

            [[saveString dataUsingEncoding:NSUTF8StringEncoding] writeToURL:savePanel.URL atomically:YES];
        }
    }];
}


- (void)exportToPdf:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
    savePanel.treatsFilePackagesAsDirectories = YES;
    if (_lastFilename != nil)
    {
        [savePanel setNameFieldStringValue:[[[_lastFilename absoluteString] lastPathComponent] stringByDeletingPathExtension]];
    }
    
    // Create an accessory view
    NSView *aView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 370, 45)];
    savePanel.accessoryView = aView;
    
    NSTextField *passwordFieldLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, aView.frame.size.height - 30, 200, 25)];
    passwordFieldLabel.stringValue = @"Export:";
    passwordFieldLabel.font = [NSFont fontWithName:@"Helvetica Neue" size:13.0];
    [passwordFieldLabel setBezeled:NO];
    [passwordFieldLabel setDrawsBackground:NO];
    [passwordFieldLabel setEditable:NO];
    [passwordFieldLabel setSelectable:NO];
    [passwordFieldLabel sizeToFit];
    [aView addSubview:passwordFieldLabel];
    
    NSComboBox *picker = [[NSComboBox alloc] initWithFrame:NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25)];
    [picker setEditable:NO];
    
    [picker addItemsWithObjectValues:@[@"Current Sheet", @"Current Selection"]];
    [picker selectItemAtIndex:([sender tag] == 9 ? 1 : 0)];
    [aView addSubview:picker];
    
    
    // Show the panel
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
        {
            [savePanel orderOut:self];
            
            NSString *dataToSave = nil;
            if (picker.indexOfSelectedItem == 0)
            {
                dataToSave = _textView.string;
            }
            else
            {
                dataToSave = [_textView.string substringWithRange:[_textView selectedRange]];
            }
            
            // Generate HTML
            NSString *baseContextFile = [[NSBundle mainBundle] pathForResource:@"HTMLTemplate" ofType:@"html"];
            NSString *baseHTMLString = [NSString stringWithContentsOfFile:baseContextFile encoding:NSUTF8StringEncoding error:NULL];
            NSString *newString = [self convertStringToHTML:dataToSave];
            NSString *saveString = [NSString stringWithFormat:baseHTMLString, [[_lastFilename path] lastPathComponent], newString];

            _exportURL = savePanel.URL;

            NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
            WebView *webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, printInfo.paperSize.width, printInfo.paperSize.height) frameName:@"PrintFrame" groupName:@"PrintGroup"];
            webView.frameLoadDelegate = self;
            [[webView mainFrame] loadHTMLString:saveString baseURL:[NSURL URLWithString:@""]];
        }
    }];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo.dictionary addEntriesFromDictionary:@{
                                                     NSPrintJobDisposition: NSPrintSaveJob,
                                                     NSPrintJobSavingURL: _exportURL
                                                     }];

    NSPrintOperation *op = [NSPrintOperation printOperationWithView:sender.mainFrame.frameView.documentView printInfo:printInfo];
    op.showsPrintPanel = NO;
    op.showsProgressPanel = YES;
    [op runOperation];

    _exportURL = nil;
}


- (void)exportToCX:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"cx"]];
    savePanel.treatsFilePackagesAsDirectories = YES;
    if (_lastFilename != nil)
    {
        [savePanel setNameFieldStringValue:[[[_lastFilename absoluteString] lastPathComponent] stringByDeletingPathExtension]];
    }

    // Create an accessory view
    NSView *aView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 100)];
    savePanel.accessoryView = aView;

    // Add export label and picker
    NSTextField *exportLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, aView.frame.size.height - 30, 70, 25)];
    exportLabel.stringValue = @"Export:";
    exportLabel.font = [NSFont fontWithName:@"Helvetica Neue" size:13.0];
    exportLabel.alignment = NSRightTextAlignment;
    [exportLabel setBezeled:NO];
    [exportLabel setDrawsBackground:NO];
    [exportLabel setEditable:NO];
    [exportLabel setSelectable:NO];
    [aView addSubview:exportLabel];

    NSComboBox *picker = [[NSComboBox alloc] initWithFrame:NSMakeRect(exportLabel.frame.size.width + 5.0, exportLabel.frame.origin.y, aView.frame.size.width - exportLabel.frame.size.width - 10.0, 25)];
    [picker setEditable:NO];

    [picker addItemsWithObjectValues:@[@"Current Sheet", @"Current Selection"]];
    [picker selectItemAtIndex:([sender tag] == 9 ? 1 : 0)];
    [aView addSubview:picker];


    // Add password fields
    NSTextField *passwordFieldLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, exportLabel.frame.origin.y - exportLabel.frame.size.height - 5, 70, 25)];
    passwordFieldLabel.stringValue = @"Password:";
    passwordFieldLabel.font = [NSFont fontWithName:@"Helvetica Neue" size:13.0];
    passwordFieldLabel.alignment = NSRightTextAlignment;
    [passwordFieldLabel setBezeled:NO];
    [passwordFieldLabel setDrawsBackground:NO];
    [passwordFieldLabel setEditable:NO];
    [passwordFieldLabel setSelectable:NO];
    [aView addSubview:passwordFieldLabel];


    NSSecureTextField *passwordField1 = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, passwordFieldLabel.frame.origin.y, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25)];
    if ([passwordField1 respondsToSelector:@selector(setPlaceholderString:)])
    {
        passwordField1.placeholderString = @"Enter your password";
    }
    else
    {
        [passwordField1.cell setPlaceholderString:@"Enter your password"];
    }
    [aView addSubview:passwordField1];

    NSSecureTextField *passwordField2 = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(passwordField1.frame.origin.x, passwordField1.frame.origin.y - passwordField1.frame.size.height - 5.0, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25)];
    if ([passwordField2 respondsToSelector:@selector(setPlaceholderString:)])
    {
        passwordField2.placeholderString = @"Repeat your password";
    }
    else
    {
        [passwordField2.cell setPlaceholderString:@"Enter your password"];
    }
    [aView addSubview:passwordField2];


    // Show the panel
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
        {
            // Hide panel
            [savePanel orderOut:self];

            // Check passwords
            if ([passwordField1.stringValue isEqualToString:passwordField2.stringValue] == NO)
            {
                [self showMsg:@"Error!" withInfo:@"Passwords does not match." withAlertStyle:NSCriticalAlertStyle];
                return;
            }

            // Get password
            NSString *password = passwordField1.stringValue;

            // Create new dictionary object
            NSMutableDictionary *dataToSave = [NSMutableDictionary dictionary];
            [dataToSave setObject:@"v001" forKey:@"version"];
            [dataToSave setObject:@(0) forKey:@"sel_sheet"];

            // Add data
            if (picker.indexOfSelectedItem == 0)
            {
                [dataToSave setObject:[NSMutableArray arrayWithObject:[@{
                                                                         @"title": [_currentSheet objectForKey:@"title"],
                                                                         @"data": _textView.string,
                                                                         @"range": NSStringFromRange(NSMakeRange(0, 0))
                                                                         } mutableCopy]] forKey:@"items"];
            }
            else
            {
                [dataToSave setObject:[NSMutableArray arrayWithObject:[@{
                                                                         @"title": [_currentSheet objectForKey:@"title"],
                                                                         @"data": [_textView.string substringWithRange:[_textView selectedRange]],
                                                                         @"range": NSStringFromRange(NSMakeRange(0, 0))
                                                                         } mutableCopy]] forKey:@"items"];
            }

            // Make encrypted data
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataToSave options:0 error:nil];
            NSData *finalFile = [jsonData gzippedData];
            finalFile = [PasswordManager encryptData:finalFile withPassword:password error:nil];

            // Write stuff to the file
            NSURL *filename = [savePanel URL];
            BOOL success = [finalFile writeToURL:filename atomically:YES];

            // Show error in case something failed
            if (success == NO)
            {
                [self showMsg:@"Error writing file!" withInfo:@"Make sure you have access to the folder." withAlertStyle:NSCriticalAlertStyle];
            }
        }
    }];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    switch (menuItem.tag)
    {
        case 1: // Lock
        case 5: // Save
        case 6: // Save As
        case 7: // Print
        case 8: // Print
            if (_decryptedData == nil)
            {
                return NO;
            }
            break;

        case 4: // Close document
            if (_decryptedData == nil && _lockedFilename == nil)
            {
                return NO;
            }
            break;

        case 51: // Next Sheet
        case 52: // Previous Sheet
            if (_decryptedData == nil || [[_decryptedData objectForKey:@"items"] count] <= 1)
            {
                return NO;
            }
            break;
    }
    return YES;
}


- (void)shiftRight:(id)sender
{
    NSRange sel = [_textView selectedRange];
    NSRange lineRange = [_textView.string lineRangeForRange:sel];
    if (lineRange.length > 0) {
        NSString *oldText = [_textView.string substringWithRange:lineRange];
        NSMutableArray *lines = [[oldText componentsSeparatedByString:@"\n"] mutableCopy];
        NSMutableArray *linesMod = [lines mutableCopy];
        for (int i = 0; i < lines.count - 1; ++i) {
            NSString *line = [lines objectAtIndex:i];
            line = [NSString stringWithFormat:@"    %@", line];
            [linesMod setObject:line atIndexedSubscript:i];
        }

        // Replace new text
        NSString *newText = [linesMod componentsJoinedByString:@"\n"];
        [_textView setSelectedRange:lineRange];
        [_textView insertText:newText];

        // Select same previous selection
        NSInteger lineCount = lines.count - 1;
        if (sel.location > lineRange.location) {
            sel.location += 4;
            lineCount -= 1;
        }
        if (sel.length > 0) {
            sel.length += (lineCount * 4);
        }
        [_textView setSelectedRange:sel];

        // Parse
        [((CTextView *)_textView).hl parseAndHighlightNow];
    }
}

- (void)shiftLeft:(id)sender
{
    NSRange sel = [_textView selectedRange];
    NSRange lineRange = [_textView.string lineRangeForRange:sel];
    if (lineRange.length > 0) {
        NSString *oldText = [_textView.string substringWithRange:lineRange];
        NSMutableArray *lines = [[oldText componentsSeparatedByString:@"\n"] mutableCopy];
        NSMutableArray *linesMod = [lines mutableCopy];

        for (int i = 0; i < lines.count - 1; ++i) {
            NSString *line = [[lines objectAtIndex:i] mutableCopy];
            line = [line stringByReplacingOccurrencesOfString:@"    " withString:@"" options:0 range:NSMakeRange(0, 4)];
            [linesMod setObject:line atIndexedSubscript:i];
        }

        // Replace new text
        NSString *newText = [linesMod componentsJoinedByString:@"\n"];
        [_textView setSelectedRange:lineRange];
        [_textView insertText:newText];

        // Select same previous selection
        NSInteger lineCount = lines.count - 1;
        if (sel.location > lineRange.location) {
            sel.location -= 4;
            lineCount -= 1;
        }
        if (sel.length > 0) {
            sel.length -= (lineCount * 4);
        }
        [_textView setSelectedRange:sel];

        // Parse
        [((CTextView *)_textView).hl parseAndHighlightNow];
    }
}


#pragma mark - Sheet Control

- (void)newSheet:(id)sender
{
    if (_decryptedData == nil)
    {
        return;
    }
    NSMutableArray *items = [_decryptedData objectForKey:@"items"];
    [items addObject:[@{@"title": @"Untitled", @"data": @"", @"range": NSStringFromRange(NSMakeRange(0, 0))} mutableCopy]];
    [_tableView reloadData];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:items.count - 1] byExtendingSelection:NO];
}


- (void)nextSheet:(id)sender
{
    if (_decryptedData == nil)
    {
        return;
    }
    NSInteger row = [_tableView selectedRow];
    if (row < [[_decryptedData objectForKey:@"items"] count])
    {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row + 1] byExtendingSelection:NO];
    }
}


- (void)previousSheet:(id)sender
{
    if (_decryptedData == nil)
    {
        return;
    }
    NSInteger row = [_tableView selectedRow];
    if (row > 0)
    {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row - 1] byExtendingSelection:NO];
    }
}


- (void)_deleteSheet
{
    _textView.string = @"";
    NSInteger newTabIndex = [_tableView selectedRow];
    [[_decryptedData objectForKey:@"items"] removeObjectAtIndex:(NSUInteger)newTabIndex];
    
    if ([[_decryptedData objectForKey:@"items"] count] <= newTabIndex)
    {
        newTabIndex -= 1;
    }
    if ([[_decryptedData objectForKey:@"items"] count] == 0)
    {
        [self newSheet:nil];
    }
    newTabIndex = MAX(newTabIndex, 0);

    // Delete undo data
    [_textView.undoManager removeAllActions];

    // Reload sheet list
    [_tableView reloadData];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newTabIndex] byExtendingSelection:NO];

    // Set document editted
    self.window.documentEdited = YES;
}

- (void)deleteSheet:(id)sender
{
    if (_decryptedData == nil)
    {
        return;
    }

    if (_textView.string.length <= 3 || _closing == YES)
    {
        [self _deleteSheet];
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];

    [alert setMessageText:@"Are you sure want to delete this sheet?"];
    [alert setInformativeText:@"This cannot be undone."];
    [alert setAlertStyle:NSWarningAlertStyle];

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn)
        {
            [self _deleteSheet];
        }
    }];
}


#pragma mark - NSTextViewDelegate

- (void)textDidChange:(NSNotification *)notification
{
    [self.window setDocumentEdited:YES];
    if (_currentSheet != nil)
    {
        [_currentSheet setObject:[_textView.string copy] forKey:@"data"];
    }
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
    if (_currentSheet != nil)
    {
        [_currentSheet setObject:NSStringFromRange(_textView.selectedRange) forKey:@"range"];
    }
}

- (NSMenu *)textView:(NSTextView *)view menu:(NSMenu *)menu forEvent:(NSEvent *)event atIndex:(NSUInteger)charIndex {

    if (_exportMenuForTextView == nil) {
        return menu;
    }

    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Export To" action:nil keyEquivalent:@""];
    [menuItem setSubmenu:_exportMenuForTextView];
    [menu addItem:menuItem];
    return menu;
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if (commandSelector == @selector(insertTab:))
    {
        [textView insertText:@"    "];
        return YES;
    }
    else if (commandSelector == @selector(deleteBackward:))
    {
        NSRange sel = [textView selectedRange];
        if (sel.location >= 4 && sel.length == 0)
        {
            sel.location -= 4;
            sel.length = 4;
            NSString *test = [textView.string substringWithRange:sel];
            if ([test isEqualToString:@"    "])
            {
                [textView setSelectedRange:sel];
                [textView insertText:@""];
                textView.selectedRange = NSMakeRange(sel.location, 0);

                [((CTextView *)textView).hl parseAndHighlightNow];
                return YES;
            }
        }
    }
    else if (commandSelector == @selector(insertNewline:))
    {
        NSRange sel = [textView selectedRange];
        sel = [textView.string lineRangeForRange:sel];
        NSString *text = [textView.string substringWithRange:sel];

        int whitespaces = 0;
        for (NSUInteger i = 0; i < text.length; ++i)
        {
            if ([text characterAtIndex:i] == ' ')
            {
                whitespaces += 1;
            }
            else
            {
                break;
            }
        }

        if (whitespaces > 0)
        {
            [textView insertNewline:nil];
            [textView insertText:[@"" stringByPaddingToLength:whitespaces withString:@" " startingAtIndex:0]];
            return YES;
        }
    }
    return NO;
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (_decryptedData == nil)
    {
        return 0;
    }
    return [[_decryptedData objectForKey:@"items"] count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 30.0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    // Load tabs
    NSDictionary *item = [[_decryptedData objectForKey:@"items"] objectAtIndex:row];
    return [item objectForKey:@"title"];
}


#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (_closing == YES)
    {
        return;
    }

    // Load new tab
    NSInteger newTabIndex = [notification.object selectedRow];
    if (newTabIndex == _currentSheetNumber)
    {
        return;
    }

    [self loadSheet:newTabIndex];
    [_decryptedData setObject:@(newTabIndex) forKey:@"sel_sheet"];
}



- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:BasicTableViewDragAndDropDataType] owner:self];
    [pboard setData:data forType:BasicTableViewDragAndDropDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return (dropOperation == NSTableViewDropAbove);
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *rowData = [pboard dataForType:BasicTableViewDragAndDropDataType];
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
    NSInteger from = [rowIndexes firstIndex];
    NSInteger to = row;
    NSInteger selected = [_tableView selectedRow];

    if (from < to)
    {
        to -= 1;
    }
    [[_decryptedData objectForKey:@"items"] moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:from] toIndex:to];
    [_tableView reloadData];
    if (selected == from)
    {
        selected = to;
    }
    else if (selected < to)
    {
        selected -= 1;
    }
    else
    {
        selected += 1;
    }
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
    return YES;
}



#pragma mark - CTableViewDelegate

- (void)CTableTextDidEndEditing:(NSString *)string
{
    [_currentSheet setObject:[string copy] forKey:@"title"];
}

@end
