//
//  CTextFieldCell.swift
//  Cryptex
//
//  Created by Gints Murans on 20.07.16.
//  Copyright © 2016. g. 4Apps. All rights reserved.
//

import Cocoa

class CTextFieldCell: NSTextFieldCell {

    // MARK: - View
    override func awakeFromNib() {
        self.font = NSFont(name: "Source Sans Pro", size:14.0)
        self.bezelStyle = NSTextFieldBezelStyle.roundedBezel
    }


    override func setUpFieldEditorAttributes(_ textObj: NSText) -> NSText {
        (textObj as! NSTextView).textContainerInset = NSMakeSize(5.0, 0)

        return textObj
    }


    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let rectInset = NSMakeRect(rect.origin.x + 10.0, rect.origin.y, rect.size.width - 20.0, rect.size.height)

        return super.drawingRect(forBounds: rectInset)
    }


    override func select(withFrame aRect: NSRect, in controlView: NSView, editor textObj: NSText, delegate anObject: Any?, start selStart: Int, length selLength: Int) {
        self.textColor = NSColor(r: 0, g:0, b:0, alpha:1.0)

        super.select(withFrame: aRect, in: controlView, editor: textObj, delegate: anObject, start: selStart, length: selLength)
    }


    override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            super.isHighlighted = newValue

            let isFocused: Bool = (self.controlView?.isEqual(to: self.controlView?.window?.firstResponder))!
            if (isHighlighted == true && isFocused == true) {
                self.textColor = NSColor.white
            }
            else {
                self.textColor = NSColor(r: 119.0, g:119.0, b:119.0, alpha:1.0)
            }
        }
    }
}
