//
//  AppDelegate.swift
//  Cryptex
//
//  Created by Gints Murans on 13.08.16.
//  Copyright © 2016. g. Early Bird. All rights reserved.
//

//
//  AppDelegate.m
//  Cryptex
//
//  Created by Gints Murans on 19/08/2014.
//  Copyright (c) 2014 4Apps. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set global print parameters
        let printInfo = NSPrintInfo()
        printInfo.topMargin = 56.692944
        printInfo.leftMargin = 56.692944
        printInfo.bottomMargin = 56.692944
        printInfo.leftMargin = 56.692944
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.verticalPagination = NSPrintInfo.PaginationMode.autoPagination
        printInfo.horizontalPagination = NSPrintInfo.PaginationMode.autoPagination
        NSPrintInfo.shared = printInfo
    }
}
