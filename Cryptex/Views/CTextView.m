//
//  CTextView.m
//  Cryptex
//
//  Created by Gints Murans on 29/10/14.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

#import "CTextView.h"
#import "Extensions.h"

@implementation CTextView


- (void)awakeFromNib
{
    // Update some settings
    self.textContainerInset = NSMakeSize(20.0, 20.0);
    self.font = [NSFont fontWithName:@"Open Sans" size:14.0];

    // Add Highlighter
    _hl = [[HGMarkdownHighlighter alloc] initWithTextView:self waitInterval:0.20];
    _hl.makeLinksClickable = YES;
    
    NSString *styleFilePath = [[NSBundle mainBundle] pathForResource:@"Cryptex-V002" ofType:@"style"];
    NSString *styleContents = [NSString stringWithContentsOfFile:styleFilePath encoding:NSUTF8StringEncoding error:NULL];
    [_hl applyStylesFromStylesheet:styleContents withErrorHandler:^(NSArray *errorMessages) {
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
    [_hl activate];

    // Register for drag and drop
    [self registerForDraggedTypes:@[ NSPasteboardTypeString ]];
}


#pragma mark - Drag & Drop

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        for (NSString *file in files)
        {
            CFStringRef fileExtension = (__bridge CFStringRef)[file pathExtension];
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);

            NSData *file_contents = [NSData dataWithContentsOfFile:file];
            NSString *string = nil;
            @try
            {
                if (UTTypeConformsTo(fileUTI, kUTTypeUTF16PlainText))
                {
                    string = [[NSString alloc] initWithData:file_contents encoding:NSUTF16StringEncoding];
                }
                else if (UTTypeConformsTo(fileUTI, kUTTypeUTF8PlainText) || UTTypeConformsTo(fileUTI, kUTTypeText))
                {
                    string = [[NSString alloc] initWithData:file_contents encoding:NSUTF8StringEncoding];
                }
            }
            @catch (NSException * e){}
            CFRelease(fileUTI);
            
            if (string != nil)
            {
                [self insertText:string];
            }
        }
    }
    else if ([[pboard types] containsObject:NSPasteboardTypeString])
    {
        NSString *myString = [pboard stringForType:NSPasteboardTypeString];
        [self insertText:myString];
    }

    return YES;
}


@end
