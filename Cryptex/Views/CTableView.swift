//
//  CTableView.swift
//  Cryptex
//
//  Created by Gints Murans on 20.07.16.
//  Copyright © 2016. g. Early Bird. All rights reserved.
//

import Cocoa


@objc protocol CTableViewDelegate {
    func CTableTextDidEndEditing(string: String)
}



class CTableView: NSTableView {
    var cDelegate: CTableViewDelegate?

    override var focusRingType: NSFocusRingType {
        get { return NSFocusRingType.None }
        set { super.focusRingType = newValue }
    }


    override func textDidEndEditing(notification: NSNotification) {
        if (self.cDelegate != nil) {
            let textView: NSTextView = notification.object as! NSTextView
            self.cDelegate?.CTableTextDidEndEditing(textView.string!)
        }

        super.textDidEndEditing(notification)
    }
}
