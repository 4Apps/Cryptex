//
//  CSplitView.swift
//  Cryptex
//
//  Created by Gints Murans on 29/12/14.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

import Cocoa

class CSplitView: NSSplitView, NSSplitViewDelegate {

    override func awakeFromNib() {
        self.delegate = self
    }

    override var dividerColor: NSColor {
        get {
            return NSColor(r: 220.0, g: 220.0, b: 220.0, alpha: 1.0)
        }
    }


    // MARK: - NSSplitViewDelegate
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if proposedMinimumPosition < 100 {
            return 100.0
        }
        return proposedMinimumPosition
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if proposedMaximumPosition > 400 {
         return 400.0
        }
        return proposedMaximumPosition
    }
}
