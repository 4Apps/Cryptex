//
//  CTableView.swift
//  Cryptex
//
//  Created by Gints Murans on 20.07.16.
//  Copyright © 2016. g. 4Apps. All rights reserved.
//

import Cocoa


protocol CTableViewDelegate {
    func CTableTextDidEndEditing(_ string: String)
}



class CTableView: NSTableView {
    var cDelegate: CTableViewDelegate?

    override var focusRingType: NSFocusRingType {
        get { return NSFocusRingType.none }
        set { super.focusRingType = newValue }
    }


    override func textDidEndEditing(_ notification: Notification) {
        if (self.cDelegate != nil) {
            let textView: NSTextView = notification.object as! NSTextView
            self.cDelegate?.CTableTextDidEndEditing(textView.string)
        }

        super.textDidEndEditing(notification)
    }
}
