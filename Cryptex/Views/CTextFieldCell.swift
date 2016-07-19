//
//  CTextFieldCell.swift
//  Cryptex
//
//  Created by Gints Murans on 20.07.16.
//  Copyright © 2016. g. Early Bird. All rights reserved.
//

import Cocoa

class CTextFieldCell: NSTextFieldCell {

    // MARK: - View
    override func awakeFromNib() {
        self.font = NSFont(name: "Source Sans Pro", size:14.0)
        self.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
    }


    override func setUpFieldEditorAttributes(textObj: NSText) -> NSText {
        (textObj as! NSTextView).textContainerInset = NSMakeSize(5.0, 0)

        return textObj
    }


    override func drawingRectForBounds(rect: NSRect) -> NSRect {
        let rectInset = NSMakeRect(rect.origin.x + 10.0, rect.origin.y, rect.size.width - 20.0, rect.size.height)

        return super.drawingRectForBounds(rectInset)
    }


    override func selectWithFrame(aRect: NSRect, inView controlView: NSView, editor textObj: NSText, delegate anObject: AnyObject?, start selStart: Int, length selLength: Int) {
        self.textColor = NSColor(r: 0, g:0, b:0, alpha:1.0)

        super.selectWithFrame(aRect, inView: controlView, editor: textObj, delegate: anObject, start: selStart, length: selLength)
    }


    override var highlighted: Bool {
        get { return super.highlighted }
        set {
            super.highlighted = newValue

            let isFocused: Bool = (self.controlView?.isEqualTo(self.controlView?.window?.firstResponder))!
            if (highlighted == true && isFocused == true) {
                self.textColor = NSColor.whiteColor()
            }
            else {
                self.textColor = NSColor(r: 119.0, g:119.0, b:119.0, alpha:1.0)
            }
        }
    }
}
