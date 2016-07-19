//
//  Extensions1.swift
//  Cryptex
//
//  Created by Gints Murans on 20.07.16.
//  Copyright © 2016. g. Early Bird. All rights reserved.
//

import Cocoa

public extension NSColor {
    public convenience init(r:CGFloat, g:CGFloat, b:CGFloat, alpha:CGFloat) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
    }

    public class func colorWithR(r:CGFloat, g:CGFloat, b:CGFloat, alpha:CGFloat) -> NSColor {
        return NSColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
    }
}

