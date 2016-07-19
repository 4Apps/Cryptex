//
//  CTextView.swift
//  Cryptex
//
//  Created by Gints Murans on 19.07.16.
//  Copyright © 2016. g. Early Bird. All rights reserved.
//

import Cocoa

class CTextView: NSTextView {

    var hl: HGMarkdownHighlighter?

    // MARK: - View
    override func awakeFromNib() {
        // Update some settings
        self.textContainerInset = NSMakeSize(20.0, 20.0)
        self.font = NSFont(name: "Source Sans Pro", size:14.0)

        // Add Highlighter
        hl = HGMarkdownHighlighter(textView: self, waitInterval: 0.20)
        hl!.makeLinksClickable = true

        let styleFilePath = NSBundle.mainBundle().pathForResource("Cryptex-V002", ofType: "style")
        var styleContents = ""
        do {
            styleContents = try String(contentsOfFile: styleFilePath!, encoding: NSUTF8StringEncoding)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not read style file"
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.addButtonWithTitle("OK")
            alert.runModal()
        }

        hl!.applyStylesFromStylesheet(styleContents) { (errorMessages: [AnyObject]!) in
            var errorsInfo: String = ""

            for str: String in (errorMessages as! [String]) {
                errorsInfo += "• "
                errorsInfo += str
                errorsInfo += "\n"
            }

            let alert = NSAlert()
            alert.messageText = "There were some errors when parsing the stylesheet:"
            alert.informativeText = errorsInfo
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.addButtonWithTitle("OK")
            alert.runModal()
        }

        hl!.activate()

        // Register for drag and drop
        self.registerForDraggedTypes([NSPasteboardTypeString])
    }


    // MARK: - Drag & Drop

    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pboard: NSPasteboard = sender.draggingPasteboard()

        if (pboard.types?.contains(NSFilenamesPboardType) == true) {
            let files = pboard.propertyListForType(NSFilenamesPboardType)
            for file: String in (files as! [String]) {
                let fileExtension: CFStringRef = (file as NSString).pathExtension
                let fileUTI: CFStringRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil) as! CFStringRef

                let file_contents: NSData! = NSData(contentsOfFile: file)
                var string: String? = nil
                if (UTTypeConformsTo(fileUTI, kUTTypeUTF16PlainText)) {
                    string = String(data: file_contents, encoding: NSUTF16StringEncoding)
                }
                else if (UTTypeConformsTo(fileUTI, kUTTypeUTF8PlainText) || UTTypeConformsTo(fileUTI, kUTTypeText)) {
                    string = String(data: file_contents, encoding: NSUTF8StringEncoding)
                }

                if (string != nil) {
                    self.insertText(string!)
                }
            }
        } else if (pboard.types?.contains(NSPasteboardTypeString) == true) {
            string = pboard.stringForType(NSPasteboardTypeString)
            self.insertText(string!)
        }

        return true
    }
}
