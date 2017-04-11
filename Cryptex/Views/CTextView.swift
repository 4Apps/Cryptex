//
//  CTextView.swift
//  Cryptex
//
//  Created by Gints Murans on 19.07.16.
//  Copyright © 2016. g. 4Apps. All rights reserved.
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

        let styleFilePath = Bundle.main.path(forResource: "Cryptex-V002", ofType: "style")
        var styleContents = ""
        do {
            styleContents = try String(contentsOfFile: styleFilePath!, encoding: String.Encoding.utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not read style file"
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        hl!.applyStyles(fromStylesheet: styleContents) { (errorMessages: [Any]?) in
            var errorsInfo: String = ""

            for str: String in (errorMessages as! [String]) {
                errorsInfo += "• "
                errorsInfo += str
                errorsInfo += "\n"
            }

            let alert = NSAlert()
            alert.messageText = "There were some errors when parsing the stylesheet:"
            alert.informativeText = errorsInfo
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        hl!.activate()

        // Register for drag and drop
        self.register(forDraggedTypes: [NSPasteboardTypeString])
    }


    // MARK: - Drag & Drop

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard: NSPasteboard = sender.draggingPasteboard()

        if (pboard.types?.contains(NSFilenamesPboardType) == true) {
            let files = pboard.propertyList(forType: NSFilenamesPboardType)
            for file: String in (files as! [String]) {
                let fileExtension: CFString = (file as NSString).pathExtension as CFString
                let fileUTI: CFString = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil) as! CFString

                let file_contents: Data! = try? Data(contentsOf: URL(fileURLWithPath: file))
                var string: String? = nil
                if (UTTypeConformsTo(fileUTI, kUTTypeUTF16PlainText)) {
                    string = String(data: file_contents, encoding: String.Encoding.utf16)
                }
                else if (UTTypeConformsTo(fileUTI, kUTTypeUTF8PlainText) || UTTypeConformsTo(fileUTI, kUTTypeText)) {
                    string = String(data: file_contents, encoding: String.Encoding.utf8)
                }

                if (string != nil) {
                    self.insertText(string!)
                }
            }
        } else if (pboard.types?.contains(NSPasteboardTypeString) == true) {
            string = pboard.string(forType: NSPasteboardTypeString)
            self.insertText(string!)
        }

        return true
    }
}
