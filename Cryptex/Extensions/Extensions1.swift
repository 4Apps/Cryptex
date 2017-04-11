//
//  Extensions1.swift
//  Cryptex
//
//  Created by Gints Murans on 20.07.16.
//  Copyright © 2016. g. 4Apps. All rights reserved.
//

import Cocoa

public extension NSColor {
    public convenience init(r:CGFloat, g:CGFloat, b:CGFloat, alpha:CGFloat) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
    }

    public class func colorWithR(_ r:CGFloat, g:CGFloat, b:CGFloat, alpha:CGFloat) -> NSColor {
        return NSColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
    }
}

extension String {
    init(NSRange range: NSRange) {
        self = NSStringFromRange(range)
    }

    func NSRange() -> NSRange {
        return NSRangeFromString(self)
    }

    func range(_ start: Int, length: Int) -> Range<String.Index> {
        return self.characters.index(self.startIndex, offsetBy: start) ..< self.characters.index(self.startIndex, offsetBy: start + length)
    }

    func range(_ start: Int, end: Int) -> Range<String.Index> {
        return self.characters.index(self.startIndex, offsetBy: start) ..< self.characters.index(self.startIndex, offsetBy: end)
    }

    func range(_ nsRange : NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex) else {
            return nil
        }
        guard let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex) else {
            return nil
        }
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
            return from ..< to
        }
        return nil
    }

    func NSRangeFromRange(_ range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        let to = String.UTF16View.Index(range.upperBound, within: utf16view)

        return NSMakeRange(utf16view.startIndex.distance(to: from), from.distance(to: to))
    }
}
