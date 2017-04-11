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
import PasswordManagerOSX
import WebKit

//fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l < r
//  case (nil, _?):
//    return true
//  default:
//    return false
//  }
//}
//
//fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l <= r
//  default:
//    return !(rhs < lhs)
//  }
//}


//@import PasswordManagerOSX

//#import "AppDelegate.h"
//#import <PasswordManagerOSX/PasswordManagerOSX-Swift.h>
//#import "BFImage.h"
//#import "GZIP.h"
//#import "HGMarkdownHighlighter.h"
//#import <WebKit/WebKit.h>
//
//#ifdef ADHOC
//#import <Sparkle/SUUpdater.h>
//#endif

typealias DecryptedDataType = Dictionary<String, Any>
typealias ItemsElementType = Dictionary<String, Any>
typealias ItemsType = Array<ItemsElementType>

let BasicTableViewDragAndDropDataType = "BasicTableViewDragAndDropDataType"
let FileFormatVersion = "v001"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, CTableViewDelegate, NSTextViewDelegate, WebFrameLoadDelegate {

    // Some instance variables
    var closing = false
    var documentSavedCallback: ()->() = {
        (void) in
    }

    var lastFilename: URL?,
        lockedFilename: URL?,
        exportURL: URL?

    var password: String?

    // Decrypted data
    var decryptedData: DecryptedDataType?,
        currentSheetNumber: Int = 0

    var currentSheet: ItemsElementType? {
        get {
            guard let decData = self.decryptedData else {
                return nil
            }

            guard let items = decData["items"] as? ItemsType else {
                return nil
            }

            if self.currentSheetNumber < 0 || self.currentSheetNumber >= items.count {
                return nil
            }

            return items[currentSheetNumber]
        }
    }

    // Tabs and text
    @IBOutlet weak var splitView: CSplitView!
    @IBOutlet weak var textScrollView: NSScrollView!
    var textView: CTextView! {
        get {
            return textScrollView.contentView.documentView as! CTextView
        }
    }
    @IBOutlet weak var tableView: CTableView!

    // Lock screen
    @IBOutlet weak var lockScreen: NSView!
    @IBOutlet weak var lockFilenameField: NSTextField!
    @IBOutlet weak var lockPasswordField: NSSecureTextField!

    // Other
    @IBOutlet weak var exportMenu: NSMenu!
    var exportMenuForTextView: NSMenu?

    @IBOutlet weak var window: INAppStoreWindow!
    @IBOutlet weak var mainView: NSView!

//#ifdef ADHOC
//- (void)checkForUpdate:(NSMenuItem *)sender
//{
//    [[SUUpdater sharedUpdater] checkForUpdates:sender]
//}
//#endif

    func applicationWillFinishLaunching(_ notification: Notification) {
//        #ifdef ADHOC
//            // Insert Check For Updates menu
//            NSMenu *mainMenu = [NSApp mainMenu]
//            NSMenu *appMenu = [[mainMenu itemAtIndex:0] submenu]
//            NSMenuItem *uploadMenu = [[NSMenuItem alloc] init]
//            [uploadMenu setTitle:NSLocalizedString(@"Check for Updates", nil)]
//            [uploadMenu setTarget:self]
//            [uploadMenu setAction:@selector(checkForUpdate:)]
//            [appMenu insertItem:uploadMenu atIndex:1]
//
//            NSMenuItem *separator = [NSMenuItem separatorItem]
//            [appMenu insertItem:separator atIndex:1]
//        #endif

        // Setup window
        if let window = self.window {
            window.showsTitle = true
            window.verticallyCenterTitle = true
            window.titleBarHeight = 38.0
            window.hideTitleBarInFullScreen = true
            window.baselineSeparatorColor = NSColor(r: 190.0, g:190.0, b:190.0, alpha:190.0)
            window.centerTrafficLightButtons = true
            window.trafficLightButtonsLeftMargin = 12.0
        }

        // Add lockscreen for better visual look on startup
        splitView?.isHidden = true

        lockScreen?.frame = mainView!.frame
        lockScreen?.isHidden = true
        mainView?.addSubview(lockScreen!)
    }


    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set global print parameters
        let printInfo = NSPrintInfo()
        printInfo.topMargin = 56.692944
        printInfo.leftMargin = 56.692944
        printInfo.bottomMargin = 56.692944
        printInfo.leftMargin = 56.692944
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.verticalPagination = NSPrintingPaginationMode.autoPagination
        printInfo.horizontalPagination = NSPrintingPaginationMode.autoPagination

        NSPrintInfo.setShared(printInfo)

        // Set delegates
        self.window!.delegate = self
        tableView?.cDelegate = self

        // Register for file drag and drop
        tableView?.register(forDraggedTypes: [BasicTableViewDragAndDropDataType])

        // Listen for sleep notifications
        NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(AppDelegate.receiveSleepNote(_:)), name: NSNotification.Name.NSWorkspaceWillSleep, object: nil)
        NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(AppDelegate.receiveSleepNote(_:)), name: NSNotification.Name.NSWorkspaceScreensDidSleep, object: nil)
        NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(AppDelegate.receiveSleepNote(_:)), name: NSNotification.Name.NSWorkspaceSessionDidResignActive, object: nil)

        // Set textview delegate
        if let exportMenu = self.exportMenu {
            exportMenuForTextView = exportMenu.copy() as? NSMenu
            for item in exportMenuForTextView!.items {
                item.tag = 9
            }
        }

        // Finally open last document or create a new one
        self.lastFilename = NSDocumentController.shared().recentDocumentURLs.first

        if (self.lockedFilename == nil) { // Because openFile is run before applicationDidFinishLaunching
            if self.lastFilename != nil {
                // At applicationWillFinishLaunching file is, for some reason, not readable, so we do this here
                if FileManager.default.isReadableFile(atPath: self.lastFilename!.path) {
                    self.open(usingUrl: self.lastFilename!)
                } else {
                    self.lastFilename = nil
                    self.newDocument(nil)
                }
            } else {
                self.newDocument(nil)
            }
        }
    }


    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if filename.hasSuffix(".cx") == false {
            return false
        }

        self.open(usingUrl: URL(fileURLWithPath: filename))

        return true
    }


    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply {
        if self.window!.isDocumentEdited == true {
            let alert = NSAlert()
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Document not saved! Do you want to save it first?"
            alert.alertStyle = NSAlertStyle.warning

            alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode: NSModalResponse) in
                // Hide alert before any open/save dialogs appear
                alert.window.orderOut(nil)

                if returnCode == NSAlertFirstButtonReturn {
                    self.documentSavedCallback = { () in
                        if self.window!.isDocumentEdited == false {
                            self.closeFile()
                            NSApplication.shared().terminate(self)
                        }
                    }

                    self.saveDocument(nil)
                } else if (returnCode == NSAlertSecondButtonReturn) {
                    self.closeFile()
                    NSApplication.shared().terminate(self)
                }
            })

            return NSApplicationTerminateReply.terminateCancel
        }

        // Close the file if its open
        self.closeFile()

        // Terminate the process
        return NSApplicationTerminateReply.terminateNow
    }


    // MARK: - NSWorkspace notifications

    func receiveSleepNote(_ note: Notification) {
        if decryptedData != nil && password != nil {
            self.lockFileWithFilename(lastFilename)
        }
    }


    // MARK: - Helpers

    func showMsg(_ msg: String, info: String, alertStyle: NSAlertStyle) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")

            alert.messageText = msg
            alert.informativeText = info
            alert.alertStyle = alertStyle

            alert.beginSheetModal(for: self.window!, completionHandler: nil)
        }
    }


    func updateCurrentTitles() {
        var filename = ""
        if lockedFilename != nil {
            filename = (lockedFilename!.path as NSString).lastPathComponent
        } else if lastFilename != nil {
            filename = (lastFilename!.path as NSString).lastPathComponent
        } else {
            filename = "Untitled.cx"
        }

        self.window!.title = filename
    }


    func removeLockscreen() {
        if lockScreen!.isHidden == false {
            lockScreen!.isHidden = true
            lockPasswordField!.stringValue = ""
            lockedFilename = nil
        }

        if splitView!.isHidden == true {
            splitView!.isHidden = false
        }
    }


    func open(usingUrl filename: URL) {
        if decryptedData != nil {
            if self.window!.isDocumentEdited == true {
                let alert = NSAlert()
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                alert.addButton(withTitle: "Cancel")
                alert.messageText = "Document not saved! Do you want to save it first?"
                alert.alertStyle = NSAlertStyle.warning

                alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode: NSModalResponse) in
                    // Hide alert before any open/save dialogs appear
                    alert.window.orderOut(nil)

                    if (returnCode == NSAlertFirstButtonReturn) {
                        self.documentSavedCallback = { () in
                            if self.window!.isDocumentEdited == false {
                                self.closeFile()
                                self.open(usingUrl: filename)
                            }
                        }

                        self.saveDocument(nil)
                    } else if returnCode == NSAlertSecondButtonReturn {
                        self.closeFile()
                        self.open(usingUrl: filename)
                    }
                })

                return
            }

            // Close the file if its open
            self.closeFile()
        }

        print("Open: \(filename)")

        if FileManager.default.isReadableFile(atPath: filename.path) == false {
            self.showMsg("Error reading the file!", info: "Make sure you have access to the file.", alertStyle: NSAlertStyle.critical)
            return
        }

        // Try to load encrypted data
        var data = Data()
        do {
            data = try Data(contentsOf: filename)
        } catch {
            self.showMsg("Error reading the file!", info: "Make sure you have access to the file.", alertStyle: NSAlertStyle.critical)
            self.window!.makeKeyAndOrderFront(nil)
            return
        }

        // When we have checked that the file is accessible, ask for password
        if password == nil {
            self.lockFileWithFilename(filename)
            self.window!.makeKeyAndOrderFront(nil)
            return
        }

        // Try to decrypt data
        var error: NSError?
        guard let decryptedData = PasswordManager.decryptData(data, withPassword: password!, error: &error) else {
            var description = ""
            if error != nil {
                description = error!.description
            }
            self.showMsg("Error decrypting the file!", info: "Wrong password, I guess!\n\n\(description)", alertStyle: NSAlertStyle.critical)
            self.window!.makeKeyAndOrderFront(nil)
            self.window!.makeFirstResponder(lockPasswordField)
            return
        }

        guard let unzippedData = (decryptedData as NSData).gunzipped() else {
            self.showMsg("Error!", info: "Could not decompress data!", alertStyle: NSAlertStyle.critical)
            return
        }

        var jsonData = DecryptedDataType()
        do {
            jsonData = try JSONSerialization.jsonObject(with: unzippedData, options: JSONSerialization.ReadingOptions.mutableContainers) as! DecryptedDataType
        } catch {
            self.showMsg("Error!", info: "Error deserializing data!", alertStyle: NSAlertStyle.critical)
            self.window!.makeKeyAndOrderFront(nil)
            self.window!.makeFirstResponder(lockPasswordField)
            return
        }

        // Remove lockscreen
        self.removeLockscreen()

        // Load new ones
        self.decryptedData = jsonData
        self.lastFilename = filename
        self.updateCurrentTitles()

        // Save some defaults
        NSDocumentController.shared().noteNewRecentDocumentURL(lastFilename!)
        UserDefaults.standard.set(lastFilename, forKey: "LastFilename")
        UserDefaults.standard.synchronize()

        // Load sheets
        if let items = self.decryptedData!["items"] as? ItemsType , items.count > 0 {
            let selSheet = self.decryptedData!["sel_sheet"] as! Int
            let selectedSheet = (selSheet <= items.count ? selSheet : 0)

            tableView!.reloadData()
            tableView!.selectRowIndexes(IndexSet(integer: selectedSheet), byExtendingSelection: false)
        } else {
            self.newSheet()
        }

        // Make window active
        self.window.makeKeyAndOrderFront(nil)
        self.window.makeFirstResponder(textView)
    }


    func save(data: DecryptedDataType, toFile filename: URL) -> Bool {
        print("Save to: \(filename)")

        var jsonData = Data()
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data, options:JSONSerialization.WritingOptions())
        } catch {
            self.showMsg("Error!", info: "JSON serialization error.", alertStyle: NSAlertStyle.critical)
            return false
        }

        guard let zippedData = (jsonData as NSData).gzipped() else {
            self.showMsg("Error!", info: "Could not compress data.", alertStyle: NSAlertStyle.critical)
            return false
        }

        var error: NSError?
        guard let finalData = PasswordManager.encryptData(zippedData, withPassword:password!, error:&error) else {
            var description = ""
            if error != nil {
                description = error!.description
            }
            self.showMsg("Error!", info: "Could not encrypt data: \(description).", alertStyle: NSAlertStyle.critical)
            return false
        }

        // Write stuff to the file
        do {
            try finalData.write(to: filename, options: .atomic)
        } catch {
            self.showMsg("Error writing file!", info: "Make sure you have access to the folder.", alertStyle: NSAlertStyle.critical)
            return false
        }

        return true
    }


    func closeFile() {
        closing = true

        lockedFilename = nil
        lastFilename = nil
        currentSheetNumber = -1
        decryptedData = nil

        tableView!.reloadData()
        textView!.string = ""
        textView!.hl?.clearHighlighting()

        password = nil
        closing = false

        self.window!.isDocumentEdited = false

        // Delete undo data
        textView?.undoManager?.removeAllActions()
    }


    func lockFileWithFilename(_ filename: URL?) {
        if self.lockScreen!.isHidden == false &&
            self.lockedFilename != nil &&
            filename != nil &&
            self.lockedFilename == filename {
            return
        }

        // Save it first, 
        // no "self.window!.documentEdited == true" check here, because we would like to save changed selection on locking
        if self.decryptedData != nil {
            self.saveDocument(nil)
            if filename == nil {
                return
            }

            // Clear memory
            self.closeFile()
        }

        // Save reference to the filename that we are locking up
        self.lastFilename = nil
        self.lockedFilename = filename // TODO: What if filename is null here?
        self.lockFilenameField.stringValue = "Open \"\(filename!.lastPathComponent)\""
        self.updateCurrentTitles()

        // Show lockscreen
        self.splitView.isHidden = true
        self.lockScreen.isHidden = false

        self.window.makeKeyAndOrderFront(nil)
        self.window.makeFirstResponder(lockPasswordField)
    }


    func loadSheet(_ sheetNumber: Int) {
        guard var decData = decryptedData,
            let items = decData["items"] as? ItemsType else {
                return
        }

        if sheetNumber < 0 || sheetNumber >= items.count {
            return
        }

        // Find current sheet
        currentSheetNumber = sheetNumber
        guard let currSheet = self.currentSheet else {
            return
        }

        // Before updating textview string
        var range = NSMakeRange(0, 0)
        if let tmp = currSheet["range"] as? String {
            range = tmp.NSRange()
        }

        // Set textview
        if let data = currSheet["data"] as? String {
            textView!.string = data.copy() as? String
            textView!.selectedRange = range
            textView!.hl?.parseAndHighlightAll()
        }

        // Scroll to selection
        if range.location > 0 {
            textView!.scrollRangeToVisible(range)
        }

        // Delete undo data
        textView!.undoManager?.removeAllActions()

        decData["sel_sheet"] = sheetNumber as Any?
        self.decryptedData = decData
    }


    func convertStringToHTML(_ str: String) -> String? {
        let data = str.data(using: String.Encoding.utf8)
        if data == nil {
            self.showMsg("Error", info: "There is some kind of error in data encoding.", alertStyle: NSAlertStyle.critical)
            return nil
        }

        guard let perlFile = Bundle.main.path(forResource: "Markdown", ofType: "pl") else {
            self.showMsg("Error!", info: "Could not find Markdown -> HTML convertor.", alertStyle: NSAlertStyle.critical)
            return nil
        }

        let pipe = Pipe()
//        let task = Process()
        var task: NSUserUnixTask?
        do {
            task = try NSUserUnixTask(url: URL(fileURLWithPath: "/usr/bin/perl"))
        } catch {
            return nil
        }

        guard let taskC = task else {
            return nil
        }

//        task.launchPath = "/usr/bin/perl"
//        task.arguments = [perlFile]

        taskC.standardInput = pipe.fileHandleForReading
        taskC.standardOutput = pipe.fileHandleForWriting

        pipe.fileHandleForWriting.write(data!)
        pipe.fileHandleForWriting.closeFile()

        taskC.execute(withArguments: [perlFile]) { (error) in
            if error != nil {

            }
        }

//        task.launch()
//        task.waitUntilExit()

//        let outputData = (task.standardOutput as! Pipe).fileHandleForReading.readDataToEndOfFile()
//        let resultString = String(data: outputData, encoding: String.Encoding.utf8)

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let resultString = String(data: outputData, encoding: String.Encoding.utf8)

        return resultString
    }

    func updateCurrentSheet(_ currSheet: ItemsElementType) {
        guard var decData = decryptedData,
            var items = decData["items"] as? ItemsType else {
                return
        }

        items[self.currentSheetNumber] = currSheet
        decData["items"] = items as Any?
        decryptedData = decData
    }



    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: Any) -> Bool {
        self.closeDocument(nil)

        return false
    }



    // MARK: - IBActions

    @IBAction func newDocument(_ sender: AnyObject?) {
        if self.window!.isDocumentEdited == true {
            let alert = NSAlert()
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Document not saved! Do you want to save it first?"
            alert.alertStyle = NSAlertStyle.warning

            alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode: NSModalResponse) in
                // Hide alert before any open/save dialogs appear
                alert.window.orderOut(nil)

                if (returnCode == NSAlertFirstButtonReturn) {
                    self.documentSavedCallback = { () in
                        if self.window!.isDocumentEdited == false {
                            self.closeFile()
                            self.newDocument(sender)
                        }
                    }

                    self.saveDocument(nil)
                } else if returnCode == NSAlertSecondButtonReturn {
                    self.closeFile()
                    self.newDocument(sender)
                }
            })

            return
        }

        // Close the file if its open
        self.closeFile()

        // Remove lockscreen if any
        self.removeLockscreen()

        // Create new dictionary object
        var decData = DecryptedDataType()
        decData["version"] = FileFormatVersion as Any?
        decData["sel_sheet"] = 0 as Any?

        // Fill in help data
        let hasRun = (UserDefaults.standard.bool(forKey: "HasRun") == true)
        if hasRun == false {
            let pathToHelpFile = Bundle.main.path(forResource: "help", ofType: "md")
            var helpData = ""

            do {
                helpData = try String(contentsOfFile: pathToHelpFile!, encoding:String.Encoding.utf8)
            } catch {
                helpData = ""
            }

            let items = [
                [
                    "title": "Cryptex",
                    "data": helpData,
                    "range": NSStringFromRange(NSMakeRange(0, 0))
                ]
            ]
            decData["items"] = items as Any?

            // Save that we have run for the first time, no need to show help anymore
            UserDefaults.standard.set(true, forKey:"HasRun")
            UserDefaults.standard.synchronize()
        } else {
            let items = [
                [
                    "title": "Cryptex",
                    "data": "",
                    "range": NSStringFromRange(NSMakeRange(0, 0))
                ]
            ]
            decData["items"] = items as Any?
        }

        // Set data
        self.decryptedData = decData

        // Add Tab
        tableView!.reloadData()
        tableView!.selectRowIndexes(IndexSet(integer:0), byExtendingSelection:false)

        // Set not-edited
        self.window!.isDocumentEdited = false

        // Make window active
        self.updateCurrentTitles()
        self.window!.makeKeyAndOrderFront(sender)
        self.window!.makeFirstResponder(textView)
    }


    @IBAction func saveAsDocument(_ sender: AnyObject?) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["cx"]
        savePanel.treatsFilePackagesAsDirectories = true
        if lastFilename != nil {
            savePanel.nameFieldStringValue = lastFilename!.lastPathComponent
        }

        // Create an accessory view for password fields
        let aView = NSView(frame: NSMakeRect(0, 0, 370, 150))
        savePanel.accessoryView = aView

        // Add password fields
        let passwordFieldLabel = NSTextField(frame: NSMakeRect(0, aView.frame.size.height - 32, 200, 25))
        passwordFieldLabel.stringValue = "Password:"
        passwordFieldLabel.font = NSFont(name: "Helvetica Neue", size:13.0)
        passwordFieldLabel.isBezeled = false
        passwordFieldLabel.drawsBackground = false
        passwordFieldLabel.isEditable = false
        passwordFieldLabel.isSelectable = false
        passwordFieldLabel.sizeToFit()
        aView.addSubview(passwordFieldLabel)


        let passwordField1 = NSSecureTextField(frame: NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
        if #available(OSX 10.10, *) {
            passwordField1.placeholderString = "Enter your password"
        } else {
            (passwordField1.cell as! NSTextFieldCell).placeholderString = "Enter your password"
        }
    //    passwordField1.alignment = NSCenterTextAlignment
        aView.addSubview(passwordField1)

        let passwordField2 = NSSecureTextField(frame: NSMakeRect(passwordField1.frame.origin.x, passwordField1.frame.origin.y - passwordField1.frame.size.height - 5.0, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
        if #available(OSX 10.10, *) {
            passwordField2.placeholderString = "Repeat your password"
        } else {
            (passwordField2.cell as! NSTextFieldCell).placeholderString = "Repeat your password"
        }
    //    passwordField2.alignment = NSCenterTextAlignment
        aView.addSubview(passwordField2)

        // Add description field
        let descriptionLabel = NSTextField(frame: NSMakeRect(0, 0, aView.frame.size.width, 75))
        descriptionLabel.stringValue = "Choose your password wisely. We recomend using passwords made of multiple words and spaces between them, making a sentence that makes sense only to you. For example: Big brown cow runs up in space 4 times in a row."
        descriptionLabel.font = NSFont(name: "Helvetica Neue", size: 11.0)
        descriptionLabel.cell?.wraps = true
        descriptionLabel.isBezeled = false
        descriptionLabel.drawsBackground = false
        descriptionLabel.isEditable = false
        descriptionLabel.isSelectable = false
        aView.addSubview(descriptionLabel)


        // Show the panel
        savePanel.beginSheetModal(for: self.window!) { (result: Int) in
            savePanel.orderOut(self)

            if result == NSFileHandlingPanelOKButton {
                if passwordField1.stringValue != passwordField2.stringValue {
                    self.showMsg("Error!", info: "Passwords does not match.", alertStyle: NSAlertStyle.critical)
                    return
                }

                // Not sure if this can evaluate to false
                guard let saveUrl = savePanel.url else {
                    return
                }

                // Warn about the empty password
                if passwordField1.stringValue.characters.count < 1 {
                    self.showMsg("Warning!", info:"It is generally safer to provide at least some password than no password at all.", alertStyle:NSAlertStyle.critical)
                }

                self.password = passwordField1.stringValue
                self.lastFilename = saveUrl

                if self.save(data: self.decryptedData!, toFile: self.lastFilename!) {
                    NSDocumentController.shared().noteNewRecentDocumentURL(saveUrl)
                    UserDefaults.standard.set(saveUrl, forKey:"LastFilename")
                    UserDefaults.standard.synchronize()

                    self.updateCurrentTitles()
                    self.window!.isDocumentEdited = false
                    self.documentSavedCallback()
                    self.documentSavedCallback = {}
                }
            }
        }
    }


    @IBAction func saveDocument(_ sender: AnyObject?) {
        if self.lastFilename == nil {
            self.saveAsDocument(sender)
            return
        }

        print("Save to: \(self.lastFilename)")

        if self.save(data: decryptedData!, toFile: self.lastFilename!) {
            self.window!.isDocumentEdited = false
            self.documentSavedCallback()
            self.documentSavedCallback = {}
        }
    }


    @IBAction func openDocument(_ sender: AnyObject?) {
        // If window is closed create new document first to avoid unexpected behaviour
        if self.window!.isVisible == false && lastFilename == nil {
            self.newDocument(sender)
        }

        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["cx"]
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.beginSheetModal(for: self.window!) { (result: Int) in
            openPanel.orderOut(self)

            if result == NSFileHandlingPanelOKButton {
                guard let url = openPanel.url else {
                    return
                }
                self.open(usingUrl: url)
            }
        }
    }


    @IBAction func closeDocument(_ sender: AnyObject?) {
        if self.window!.isDocumentEdited == true {
            let alert = NSAlert()
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Document not saved! Do you want to save it first?"
            alert.alertStyle = NSAlertStyle.warning

            alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode: NSModalResponse) in
                // Hide alert before any open/save dialogs appear
                alert.window.orderOut(nil)

                if (returnCode == NSAlertFirstButtonReturn) {
                    self.documentSavedCallback = {
                        () in
                        if self.window!.isDocumentEdited == false {
                            self.closeFile()
                            self.window!.close()
                        }
                    }

                    self.saveDocument(nil)
                } else if returnCode == NSAlertSecondButtonReturn {
                    self.closeFile()
                    self.window!.close()
                }
            })

            return
        }

        // Close it up
        self.closeFile()
        self.window!.close()
    }

    @IBAction func openLastDocument(_ sender: AnyObject?) {
        if let lastUrl = NSDocumentController.shared().recentDocumentURLs.first {
            self.open(usingUrl: lastUrl)
        }
    }

    @IBAction func lockDocument(_ sender: AnyObject?) {
        self.lockFileWithFilename(lastFilename)
    }

    @IBAction func unlockDocument(_ sender: AnyObject?) {
        if lockedFilename == nil {
            return
        }

        password = lockPasswordField!.stringValue.copy() as? String
        self.open(usingUrl: lockedFilename!)
    }

    @IBAction func printDocument(_ sender: AnyObject?) {
        let printInfo = NSPrintInfo.shared()
        let printView = NSTextView(frame:NSMakeRect(0, 0, printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin, textView!.frame.size.height))
        printView.string = textView!.string

        // Calculate real height of the text view
        printView.layoutManager!.glyphRange(for: printView.textContainer!)
        let containerHeight = printView.layoutManager!.usedRect(for: printView.textContainer!).size.height
        var frame = printView.frame
        frame.size.height = containerHeight
        printView.frame = frame

        // Highlighter
        let hl = HGMarkdownHighlighter(textView: printView)
        let styleFilePath = Bundle.main.path(forResource: "Cryptex-print", ofType:"style")
        var styleContents = ""
        do {
            styleContents = try String(contentsOfFile: styleFilePath!, encoding:String.Encoding.utf8)
        } catch {
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.messageText = "Error"
            alert.informativeText = "Couldn't load style file"
            alert.runModal()

            return
        }
        hl?.applyStyles(fromStylesheet: styleContents, withErrorHandler: { (errorMessages: [Any]?) in
            var errorsInfo = ""
            for str in errorMessages as! [String] {
                errorsInfo += "• "
                errorsInfo += str
                errorsInfo += "\n"
            }

            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.messageText = "There were some errors when parsing the stylesheet:"
            alert.informativeText = errorsInfo
            alert.runModal()
        })
        hl?.parseAndHighlightCallback = { () in
            NSPrintOperation(view: printView, printInfo:printInfo).runModal(for: self.window!, delegate:nil, didRun:nil, contextInfo:nil)
        }
        hl?.activate()
        hl?.parseAndHighlightNow()
    }


    @IBAction func exportToMarkdown(_ sender: AnyObject?) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["md"]
        savePanel.treatsFilePackagesAsDirectories = true
        if lastFilename != nil {
            savePanel.nameFieldStringValue = lastFilename!.deletingPathExtension().lastPathComponent
        }

        // Create an accessory view
        let aView = NSView(frame: NSMakeRect(0, 0, 370, 45))
        savePanel.accessoryView = aView

        let passwordFieldLabel = NSTextField(frame: NSMakeRect(0, aView.frame.size.height - 30, 200, 25))
        passwordFieldLabel.stringValue = "Export:"
        passwordFieldLabel.font = NSFont(name: "Helvetica Neue", size: 13.0)
        passwordFieldLabel.isBezeled = false
        passwordFieldLabel.drawsBackground = false
        passwordFieldLabel.isEditable = false
        passwordFieldLabel.isSelectable = false
        passwordFieldLabel.sizeToFit()
        aView.addSubview(passwordFieldLabel)

        let picker = NSComboBox(frame: NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
        picker.isEditable = false
        picker.addItems(withObjectValues: ["Current Sheet", "Current Selection"])
        picker.selectItem(at: sender?.tag == 9 ? 1 : 0)
        aView.addSubview(picker)

        // Show the panel
        savePanel.beginSheetModal(for: self.window!) { (result: Int) in
            savePanel.orderOut(self)

            if result == NSFileHandlingPanelOKButton {
                var stringToSave: String? = nil
                if picker.indexOfSelectedItem == 0 {
                    stringToSave = self.textView!.string!
                } else {
                    guard let range = self.textView!.string!.range(self.textView!.selectedRange) else {
                        self.showMsg("Error!", info: "Range issue.", alertStyle: NSAlertStyle.critical)
                        return
                    }
                    stringToSave = self.textView!.string!.substring(with: range)
                }

                guard let stringToSaveC = stringToSave else {
                    self.showMsg("Error!", info: "Missing string.", alertStyle: NSAlertStyle.critical)
                    return
                }

                guard let dataToSave = stringToSaveC.data(using: String.Encoding.utf8) else {
                    self.showMsg("Error!", info: "Could not convert string to uf8.", alertStyle: NSAlertStyle.critical)
                    return
                }

                do {
                    try dataToSave.write(to: savePanel.url!, options: .atomic)
                } catch {
                    self.showMsg("Error writing file!", info: "Make sure you have access to the folder.", alertStyle: NSAlertStyle.critical)
                }
            }
        }
    }


    @IBAction func exportToHtml(_ sender: AnyObject?) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["html"]
        savePanel.treatsFilePackagesAsDirectories = true
        if lastFilename != nil {
            savePanel.nameFieldStringValue = lastFilename!.deletingPathExtension().lastPathComponent
        }

        // Create an accessory view
        let aView = NSView(frame: NSMakeRect(0, 0, 370, 45))
        savePanel.accessoryView = aView

        let passwordFieldLabel = NSTextField(frame: NSMakeRect(0, aView.frame.size.height - 30, 200, 25))
        passwordFieldLabel.stringValue = "Export:"
        passwordFieldLabel.font = NSFont(name: "Helvetica Neue", size: 13.0)
        passwordFieldLabel.isBezeled = false
        passwordFieldLabel.drawsBackground = false
        passwordFieldLabel.isEditable = false
        passwordFieldLabel.isSelectable = false
        passwordFieldLabel.sizeToFit()
        aView.addSubview(passwordFieldLabel)

        let picker = NSComboBox(frame: NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
        picker.isEditable = false
        picker.addItems(withObjectValues: ["Current Sheet", "Current Selection"])
        picker.selectItem(at: sender?.tag == 9 ? 1 : 0)
        aView.addSubview(picker)

        // Show the panel
        savePanel.beginSheetModal(for: self.window!) { (result: Int) in
            savePanel.orderOut(self)

            if result == NSFileHandlingPanelOKButton {
                var stringToSave: String? = nil
                if picker.indexOfSelectedItem == 0 {
                    stringToSave = self.textView!.string!
                } else {
                    guard let range = self.textView!.string!.range(self.textView!.selectedRange) else {
                        self.showMsg("Error!", info: "Range issue.", alertStyle: NSAlertStyle.critical)
                        return
                    }
                    stringToSave = self.textView!.string!.substring(with: range)
                }

                guard let stringToSaveC = stringToSave else {
                    self.showMsg("Error!", info: "Missing string.", alertStyle: NSAlertStyle.critical)
                    return
                }

                // Generate HTML
                let baseContextFile = Bundle.main.path(forResource: "HTMLTemplate", ofType:"html")
                var baseHTMLString = ""
                do {
                    baseHTMLString = try String(contentsOfFile: baseContextFile!, encoding:String.Encoding.utf8)
                } catch {
                    self.showMsg("Error!", info: "HTML template was not found.", alertStyle: NSAlertStyle.critical)
                    return
                }

                guard let newString = self.convertStringToHTML(stringToSaveC) else {
                    self.showMsg("Error!", info: "Could not convert string to html.", alertStyle: NSAlertStyle.critical)
                    return
                }

                let saveString = String(format: baseHTMLString, self.lastFilename!.lastPathComponent, newString)
                guard let dataToSave = saveString.data(using: String.Encoding.utf8) else {
                    self.showMsg("Error!", info: "Error converting html to utf8.", alertStyle: NSAlertStyle.critical)
                    return
                }

                do {
                    try dataToSave.write(to: savePanel.url!, options: .atomic)
                } catch {
                    self.showMsg("Error writing file!", info: "Make sure you have access to the folder.", alertStyle: NSAlertStyle.critical)
                }
            }
        }
    }


    @IBAction func exportToPdf(_ sender: AnyObject?) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["pdf"]
        savePanel.treatsFilePackagesAsDirectories = true
        if lastFilename != nil {
            savePanel.nameFieldStringValue = lastFilename!.deletingPathExtension().lastPathComponent
        }

        // Create an accessory view
        let aView = NSView(frame: NSMakeRect(0, 0, 370, 45))
        savePanel.accessoryView = aView

        let passwordFieldLabel = NSTextField(frame: NSMakeRect(0, aView.frame.size.height - 30, 200, 25))
        passwordFieldLabel.stringValue = "Export:"
        passwordFieldLabel.font = NSFont(name: "Helvetica Neue", size: 13.0)
        passwordFieldLabel.isBezeled = false
        passwordFieldLabel.drawsBackground = false
        passwordFieldLabel.isEditable = false
        passwordFieldLabel.isSelectable = false
        passwordFieldLabel.sizeToFit()
        aView.addSubview(passwordFieldLabel)

        let picker = NSComboBox(frame: NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
        picker.isEditable = false
        picker.addItems(withObjectValues: ["Current Sheet", "Current Selection"])
        picker.selectItem(at: sender?.tag == 9 ? 1 : 0)
        aView.addSubview(picker)

        // Show the panel
        savePanel.beginSheetModal(for: self.window!) { (result: Int) in
            savePanel.orderOut(self)

            if result == NSFileHandlingPanelOKButton {
                var stringToSave: String? = nil
                if picker.indexOfSelectedItem == 0 {
                    stringToSave = self.textView!.string!
                } else {
                    guard let range = self.textView!.string!.range(self.textView!.selectedRange) else {
                        self.showMsg("Error!", info: "Range issue.", alertStyle: NSAlertStyle.critical)
                        return
                    }
                    stringToSave = self.textView!.string!.substring(with: range)
                }

                guard let stringToSaveC = stringToSave else {
                    self.showMsg("Error!", info: "Missing string.", alertStyle: NSAlertStyle.critical)
                    return
                }

                // Generate HTML
                let baseContextFile = Bundle.main.path(forResource: "HTMLTemplate", ofType:"html")
                var baseHTMLString = ""
                do {
                    baseHTMLString = try String(contentsOfFile: baseContextFile!, encoding:String.Encoding.utf8)
                } catch {
                    self.showMsg("Error!", info: "HTML template was not found.", alertStyle: NSAlertStyle.critical)
                    return
                }

                guard let newString = self.convertStringToHTML(stringToSaveC) else {
                    self.showMsg("Error!", info: "Could not convert string to html.", alertStyle: NSAlertStyle.critical)
                    return
                }

                let saveString = String(format: baseHTMLString, self.lastFilename!.lastPathComponent, newString)
                self.exportURL = savePanel.url

                let printInfo = NSPrintInfo.shared()
                guard let webView = WebView(frame: NSMakeRect(0, 0, printInfo.paperSize.width, printInfo.paperSize.height), frameName:"PrintFrame", groupName:"PrintGroup") else {
                    self.showMsg("Error!", info: "Webview could not be created.", alertStyle: NSAlertStyle.critical)
                    return
                }
                webView.frameLoadDelegate = self
                webView.mainFrame.loadHTMLString(saveString, baseURL:URL(string: ""))
            }
        }
    }


    func webView(_ sender: WebView, didFinishLoadFor frame: WebFrame) {
        if self.exportURL == nil {
            return
        }

        let printInfo = NSPrintInfo.shared()
        printInfo.dictionary().addEntries(
            from: [
                NSPrintJobDisposition: NSPrintSaveJob,
                NSPrintJobSavingURL: exportURL!
            ]
        )

        let op = NSPrintOperation(view: sender.mainFrame.frameView.documentView, printInfo:printInfo)
        op.showsPrintPanel = false
        op.showsProgressPanel = true
        op.run()

        exportURL = nil
    }


    @IBAction func exportToCX(_ sender: AnyObject?) {
        guard let currSheet = self.currentSheet else {
                return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["cx"]
        savePanel.treatsFilePackagesAsDirectories = true
        if lastFilename != nil {
            savePanel.nameFieldStringValue = lastFilename!.deletingPathExtension().lastPathComponent
        }

        // Create an accessory view
        let aView = NSView(frame: NSMakeRect(0, 0, 400, 100))
        savePanel.accessoryView = aView

        // Add export label and picker
        let exportLabel = NSTextField(frame: NSMakeRect(0, aView.frame.size.height - 30, 70, 25))
        exportLabel.stringValue = "Export:"
        exportLabel.font = NSFont(name: "Helvetica Neue", size: 13.0)
        exportLabel.alignment = NSRightTextAlignment
        exportLabel.isBezeled = false
        exportLabel.drawsBackground = false
        exportLabel.isEditable = false
        exportLabel.isSelectable = false
//        exportLabel.sizeToFit()
        aView.addSubview(exportLabel)

        // Create an accessory view
        let picker = NSComboBox(frame: NSMakeRect(exportLabel.frame.size.width + 5.0, exportLabel.frame.origin.y, aView.frame.size.width - exportLabel.frame.size.width - 10.0, 25))
        picker.isEditable = false
        picker.addItems(withObjectValues: ["Current Sheet", "Current Selection"])
        picker.selectItem(at: sender?.tag == 9 ? 1 : 0)
        aView.addSubview(picker)

        // Add password fields
        let passwordFieldLabel = NSTextField(frame: NSMakeRect(0, exportLabel.frame.origin.y - exportLabel.frame.size.height - 5, 70, 25))
        passwordFieldLabel.stringValue = "Password:"
        passwordFieldLabel.font = NSFont(name: "Helvetica Neue", size:13.0)
        passwordFieldLabel.alignment = NSRightTextAlignment
        passwordFieldLabel.isBezeled = false
        passwordFieldLabel.drawsBackground = false
        passwordFieldLabel.isEditable = false
        passwordFieldLabel.isSelectable = false
        aView.addSubview(passwordFieldLabel)


        let passwordField1 = NSSecureTextField(frame: NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, passwordFieldLabel.frame.origin.y, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
        if #available(OSX 10.10, *) {
            passwordField1.placeholderString = "Enter your password"
        } else {
            (passwordField1.cell as! NSTextFieldCell).placeholderString = "Enter your password"
        }
        aView.addSubview(passwordField1)

        let passwordField2 = NSSecureTextField(frame: NSMakeRect(passwordField1.frame.origin.x, passwordField1.frame.origin.y - passwordField1.frame.size.height - 5.0, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
        if #available(OSX 10.10, *) {
            passwordField2.placeholderString = "Repeat your password"
        } else {
            (passwordField2.cell as! NSTextFieldCell).placeholderString = "Repeat your password"
        }
        aView.addSubview(passwordField2)

        // Show the panel
        savePanel.beginSheetModal(for: self.window!, completionHandler: { (result: Int) in
            savePanel.orderOut(self)

            if result == NSFileHandlingPanelOKButton {
                // Check passwords
                if passwordField1.stringValue != passwordField2.stringValue {
                    self.showMsg("Error!", info: "Passwords does not match.", alertStyle: NSAlertStyle.critical)
                    return
                }

                // Get password
                let password = passwordField1.stringValue

                // Create new dictionary object
                var dataToSave = DecryptedDataType()
                dataToSave["version"] = FileFormatVersion
                dataToSave["sel_sheet"] = 0

                // Add data
                if picker.indexOfSelectedItem == 0 {
                    var item = ItemsElementType()
                    item["title"] = currSheet["title"]
                    item["data"] = self.textView!.string!
                    item["range"] = NSStringFromRange(NSMakeRange(0, 0))

                    dataToSave["items"] = [item]
                } else {
                    guard let range = self.textView!.string!.range(self.textView!.selectedRange) else {
                        self.showMsg("Error!", info: "Range issue.", alertStyle: NSAlertStyle.critical)
                        return
                    }
                    var item = ItemsElementType()
                    item["title"] = currSheet["title"]
                    item["data"] = self.textView!.string!.substring(with: range)
                    item["range"] = NSStringFromRange(NSMakeRange(0, 0))

                    dataToSave["items"] = [item]
                }

                // Make encrypted data
                var jsonData = Data()
                do {
                    jsonData = try JSONSerialization.data(withJSONObject: dataToSave, options: JSONSerialization.WritingOptions())
                } catch {
                    self.showMsg("Error!", info: "JSON serialization error.", alertStyle: NSAlertStyle.critical)
                    return
                }

                guard let zippedData = (jsonData as NSData).gzipped() else {
                    self.showMsg("Error!", info: "Could not compress data.", alertStyle: NSAlertStyle.critical)
                    return
                }

                var error: NSError?
                guard let finalData = PasswordManager.encryptData(zippedData, withPassword:password, error:&error) else {
                    var description = ""
                    if error != nil {
                        description = error!.description
                    }
                    self.showMsg("Error!", info: "Could not encrypt data: \(description).", alertStyle: NSAlertStyle.critical)
                    return
                }

                // Write stuff to the file
                do {
                    try finalData.write(to: savePanel.url!, options: .atomic)
                } catch {
                    self.showMsg("Error writing file!", info: "Make sure you have access to the folder.", alertStyle: NSAlertStyle.critical)
                }
            }
        })
    }


    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.tag {
        case 1: // Lock
            fallthrough
        case 5: // Save
            fallthrough
        case 6: // Save As
            fallthrough
        case 7: // Print
            fallthrough
        case 8:  // Print
            if decryptedData == nil {
                return false
            }
            break

        case 4: // Close document
            if decryptedData == nil && lockedFilename == nil {
                return false
            }
            break

        case 51: // Next Sheet
            fallthrough
        case 52: // Previous Sheet
            if decryptedData == nil || decryptedData!["items"] == nil || (decryptedData!["items"] as! ItemsType).count <= 1 {
                return false
            }
            break
        default:
            break;
        }

        return true
    }


    @IBAction func shiftRight(_ sender: AnyObject?) {
        // FIXME: Not finished
//        var sel = textView!.selectedRange
//        let range = textView!.string!.startIndex.advancedBy(sel.location)...textView!.string!.startIndex.advancedBy(sel.location+sel.length)
//        let lineRange = textView!.string!.lineRangeForRange(range)
//        if lineRange.startIndex.distanceTo(lineRange.endIndex) > 0 {
//            let oldText = textView!.string!.substringWithRange(lineRange)
//            var lines = oldText.componentsSeparatedByString("\n")
//            var linesMod = lines.map{ ($0.mutableCopy() as! String) } as [String]
//            for i in 0..<lines.count {
//                var line = lines[i]
//                line = "    \(line)"
//                linesMod[i] = line
//            }
//
//            // Replace new text
//            let newText = linesMod.joinWithSeparator("\n")
//            textView!.selectedRange = lineRang
//            textView!.setSelectedRange(NSRange(location: lineRange.start, length: lineRange.end))
//            textView!.insertText(newText)
//
//            // Select same previous selection
//            var lineCount = lines.count - 1
//            if sel.location > lineRange.location {
//                sel.location += 4
//                lineCount -= 1
//            }
//            if sel.length > 0 {
//                sel.length += (lineCount * 4)
//            }
//            textView!.setSelectedRange(sel)
//
//            // Parse
//            textView!.hl?.parseAndHighlightNow()
//        }
    }

    @IBAction func shiftLeft(_ sender: AnyObject?) {
        // FIXME: Not finished
//        let sel = textView!.selectedRange
//        let range = textView!.string!.startIndex.advancedBy(sel.location)...textView!.string!.startIndex.advancedBy(sel.location+sel.length)
//        let lineRange = textView!.string!.lineRangeForRange(range)
//        if lineRange.length > 0 {
//            let oldText = textView.string.substringWithRange(lineRange)
//            var lines = oldText.componentsSeparatedByString("\n").mutableCopy()
//            var linesMod = lines.mutableCopy()
//
//            for i in 0..<lines.count {
//                let line = lines.objectAtIndex(i).mutableCopy()
//                line = line.stringByReplacingOccurrencesOfString("    ", withString:"", options:0, range:NSMakeRange(0, 4))
//                linesMod.setObject(line, atIndexedSubscript:i)
//            }
//
//            // Replace new text
//            let newText = linesMod.componentsJoinedByString("\n")
//            textView.setSelectedRange(lineRange)
//            textView.insertText(newText)
//
//            // Select same previous selection
//            let lineCount = lines.count - 1
//            if sel.location > lineRange.location {
//                sel.location -= 4
//                lineCount -= 1
//            }
//            if sel.length > 0 {
//                sel.length -= (lineCount * 4)
//            }
//            textView.setSelectedRange(sel)
//
//            // Parse
//            textView.hl.parseAndHighlightNow()
//        }
    }


    // MARK: - Sheet Control

    @IBAction func newSheet(_ sender: AnyObject? = nil) {
        guard var decData = decryptedData,
                var items = decData["items"] as? ItemsType else {
            return
        }

        // Insert new sheet
        items.append([
            "title": "Untitled" as Any,
            "data": "" as Any,
            "range": NSStringFromRange(NSMakeRange(0, 0)) as Any
        ])
        decData["items"] = items as Any?
        decryptedData = decData

        // Reload table
        tableView!.reloadData()
        tableView!.selectRowIndexes(IndexSet(integer: items.count - 1), byExtendingSelection: false)
    }


    @IBAction func nextSheet(_ sender: AnyObject?) {
        guard let decData = decryptedData,
            let items = decData["items"] as? ItemsType else {
                return
        }

        let row = tableView!.selectedRow
        if row < items.count {
            tableView!.selectRowIndexes(IndexSet(integer: row + 1), byExtendingSelection: false)
        }
    }


    @IBAction func previousSheet(_ sender: AnyObject?) {
        guard decryptedData != nil else {
                return
        }

        let row = tableView!.selectedRow
        if row > 0 {
            tableView!.selectRowIndexes(IndexSet(integer: row - 1), byExtendingSelection: false)
        }
    }


    func _deleteSheet() {
        guard var decData = decryptedData,
            var items = decData["items"] as? ItemsType else {
                return
        }
        var selectedSheet = tableView!.selectedRow

        // Clear textview
        textView!.string = ""

        // Remove item
        items.remove(at: selectedSheet)
        decData["items"] = items as Any?
        decryptedData = decData

        // Delete undo data
        textView!.undoManager?.removeAllActions()

        // Reload sheet list and select next sheet
        if items.count <= selectedSheet {
            selectedSheet -= 1
        }
        if items.count == 0 {
            self.newSheet(nil)
        }
        selectedSheet = max(selectedSheet, 0)

        tableView!.reloadData()
        tableView!.selectRowIndexes(IndexSet(integer: selectedSheet), byExtendingSelection: false)

        // Set document editted
        self.window!.isDocumentEdited = true
    }

    @IBAction func deleteSheet(_ sender: AnyObject?) {
        if textView!.string != nil && textView!.string!.characters.count <= 3 || closing == true {
            self._deleteSheet()
            return
        }

        let alert = NSAlert()
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        alert.messageText = "Are you sure want to delete this sheet?"
        alert.informativeText = "This cannot be undone."
        alert.alertStyle = .warning

        alert.beginSheetModal(for: self.window!, completionHandler: { (returnCode: NSModalResponse) in
            if returnCode == NSAlertFirstButtonReturn {
                self._deleteSheet()
            }
        }) 
    }


    // MARK: - NSTextViewDelegate

    func textDidChange(_ notification: Notification) {
        guard var currSheet = self.currentSheet else {
                return
        }

        currSheet["data"] = textView!.string! as Any?
        self.updateCurrentSheet(currSheet)

        self.window!.isDocumentEdited = true
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard var currSheet = self.currentSheet else {
            return
        }

        currSheet["range"] = String(NSRange: textView!.selectedRange)
        self.updateCurrentSheet(currSheet)
    }

    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        if (exportMenuForTextView == nil) {
            return menu
        }

        let divItem = NSMenuItem.separator()
        menu.addItem(divItem)

        let menuItem = NSMenuItem(title: "Export To", action:nil, keyEquivalent:"")
        menuItem.submenu = exportMenuForTextView
        menu.addItem(menuItem)

        return menu
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let textView = textView as? CTextView,
                let textViewString = textView.string else {
            return false
        }

        if (commandSelector == #selector(NSResponder.insertTab(_:))) {
            textView.insertText("    ")

            return true
        } else if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            var sel = textView.selectedRange
            if sel.location < 4 || sel.length > 0 {
                return false
            }
            sel.location -= 4
            sel.length = 4

            let range = textViewString.range(sel.location, length: sel.length)
            let test = textViewString[range]
            if test == "    " {
                textView.replaceCharacters(in: sel, with: "")
                textView.hl?.parseAndHighlightNow()

                return true
            }
        } else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            var range = textViewString.range(textView.selectedRange.location, length: textView.selectedRange.length)
            range = textViewString.lineRange(for: range)
            let subText = textViewString.substring(with: range)

            var whitespaces = 0
            for i in 0..<subText.characters.count {
                if subText[subText.characters.index(subText.startIndex, offsetBy: i)] == " " {
                    whitespaces += 1
                } else {
                    break
                }
            }

            if whitespaces > 0 {
                textView.insertNewline(nil)
                textView.insertText("".padding(toLength: whitespaces, withPad:" ", startingAt:0))

                return true
            }
        }

        return false
    }


    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let decData = decryptedData,
            let items = decData["items"] as? ItemsType else {
                return 0
        }

        return items.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30.0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let decData = decryptedData,
            let items = decData["items"] as? ItemsType else {
                return "Error"
        }

        // Load tabs
        return items[row]["title"]
    }


    // MARK: - NSTableViewDelegate

    func tableViewSelectionDidChange(_ notification: Notification) {
        if closing == true {
            return
        }

        // Load new tab
        guard let tableView = notification.object as? NSTableView else {
            return
        }

        let newSheetIndex = tableView.selectedRow
        if newSheetIndex == currentSheetNumber {
            return
        }

        self.loadSheet(newSheetIndex)
    }


    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        // Copy the row numbers to the pasteboard.
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes([BasicTableViewDragAndDropDataType], owner:self)
        pboard.setData(data, forType:BasicTableViewDragAndDropDataType)

        return true
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return (dropOperation == NSTableViewDropOperation.above ? NSDragOperation.move : NSDragOperation())
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        guard var decData = decryptedData,
            var items = decData["items"] as? ItemsType else {
                return false
        }

        let pboard = info.draggingPasteboard()
        guard let rowData = pboard.data(forType: BasicTableViewDragAndDropDataType) else {
            return false
        }

        guard let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: rowData) as? NSIndexSet else {
            return false
        }

        let from = rowIndexes.firstIndex
        var to = row
        var selected = tableView.selectedRow

        if from < to {
            to -= 1
        }

        let item = items[from]
        items.remove(at: from)
        items.insert(item, at: to)
        decData["items"] = items as Any?
        self.decryptedData = decData

        // Reload table
        if selected == from {
            selected = to
        } else if selected < to {
            selected -= 1
        } else {
            selected += 1
        }

        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: selected), byExtendingSelection: false)

        return true
    }


    // MARK: - CTableViewDelegate

    func CTableTextDidEndEditing(_ string: String) {
        guard var currSheet = self.currentSheet else {
                return
        }

        currSheet["title"] = string as Any?
        self.updateCurrentSheet(currSheet)
    }

}
