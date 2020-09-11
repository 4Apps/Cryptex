//
//  SetPasswordView.swift
//  Cryptex
//
//  Created by Gints Murans on 18.04.2017.
//  Copyright © 2017. g. Early Bird. All rights reserved.
//

import Cocoa


typealias SetPasswordViewCallback = (_ password: String)->()

class SetPasswordView: NSBox {
    public var callback: SetPasswordViewCallback?
    public var filename: String = "" {
        didSet {
            self.filenameField.stringValue = "Set password for \"\(filename)\""
        }
    }

    override var isHidden: Bool {
        didSet {
            if isHidden == false {
                passwordField1.stringValue = ""
                passwordField2.stringValue = ""
                passwordField1.becomeFirstResponder()
            }
        }
    }

    @IBOutlet weak var filenameField: NSTextField!
    @IBOutlet weak var passwordField1: NSSecureTextField!
    @IBOutlet weak var passwordField2: NSSecureTextField!

    @IBAction func setPassword(_ sender: Any?) {
        if let callback = callback {
            callback(passwordField1.stringValue)
        }
    }
}
