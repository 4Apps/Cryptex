//
//  UnlockView.swift
//  Cryptex
//
//  Created by Gints Murans on 18.04.2017.
//  Copyright © 2017. g. Early Bird. All rights reserved.
//

import Cocoa


typealias UnlockViewCallback = (_ password: String)->()

class UnlockView: NSBox {
    public var callback: UnlockViewCallback?
    public var filename: String = "" {
        didSet {
            self.filenameField.stringValue = "Open \"\(filename)\""
        }
    }

    override var isHidden: Bool {
        didSet {
            if isHidden == false {
                passwordField.stringValue = ""
                passwordField.becomeFirstResponder()
            }
        }
    }

    @IBOutlet weak var filenameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!

    @IBAction func unlock(_ sender: Any?) {
        if let callback = callback {
            callback(passwordField.stringValue)
        }
    }
}
