//
//  WindowController.swift
//  Cryptex
//
//  Created by Gints Murans on 13.04.2017.
//  Copyright © 2017. g. Early Bird. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController{

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.shouldCascadeWindows = true
    }

}
