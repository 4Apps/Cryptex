//
//  Document.swift
//  Cryptex
//
//  Created by Gints Murans on 12.04.2017.
//  Copyright © 2017. g. Early Bird. All rights reserved.
//

import Cocoa
import PasswordManager

typealias GeneralCallback = ()->()
typealias DecryptedDataType = Dictionary<String, Any>
typealias ItemsElementType = Dictionary<String, Any>
typealias ItemsType = Array<ItemsElementType>

let FileFormatVersion = "v001"

let cxErrorDomain = "cxError"
enum cxError: Error, CustomStringConvertible {
    typealias RawValue = Int

    case serializationError

    var description: String {
        get {
            switch self {
                case .serializationError:
                    return "Data serialization error"
            }
        }
    }
}


class cxDocument: NSDocument {

    var currentWindow: NSWindow?
    var editorViewController: EditorViewController?
//    var unlockViewController: UnlockViewController?
//    var setPasswordViewController: SetPasswordViewController?

    var filename: URL?
    var password: String?
    var rawData: Data?
    var rawDataType: String?

    // How the unlocking works
    var unlockCallback: GeneralCallback?
//    var unlockViewCallback: UnlockViewCallback {
//        get {
//            return {(password) in
//                self.password = password
//                if let callback = self.unlockCallback {
//                    callback()
//                }
//            }
//        }
//    }

    // How setting the password works
    var setPasswordCallback: GeneralCallback?
//    var setPasswordViewCallback: SetPasswordViewCallback {
//        get {
//            return {password in
//                self.password = password
//                if let callback = self.setPasswordCallback {
//                    callback()
//                }
//            }
//        }
//    }

    // Decrypted data
    var decryptedData: DecryptedDataType = DecryptedDataType(),
        currentSheetNumber: Int = 0

    // Override vars
    override open class var autosavesInPlace: Bool { return true }


    // MARK: - Helpers
    func showMsg(_ msg: String, info: String, alertStyle: NSAlert.Style) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")

            alert.messageText = msg
            alert.informativeText = info
            alert.alertStyle = alertStyle

            if let window = self.currentWindow {
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
        }
    }


    // MARK: - Overrides
    override init() {
        super.init()

        decryptedData["version"] = FileFormatVersion as Any?
        decryptedData["sel_sheet"] = 0 as Any?

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

            decryptedData["items"] = [
                [
                    "title": "Cryptex",
                    "data": helpData,
                    "range": NSStringFromRange(NSMakeRange(0, 0))
                ]
            ]

            // Save that we have run for the first time, no need to show help anymore
            UserDefaults.standard.set(true, forKey:"HasRun")
            UserDefaults.standard.synchronize()
        } else {
            decryptedData["items"] = [
                    [
                        "title": "Cryptex",
                        "data": "",
                        "range": NSStringFromRange(NSMakeRange(0, 0))
                    ]
            ]
        }
    }

    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
        return true
    }

    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        guard let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Document Window Controller")) as? NSWindowController else {
            self.showMsg("Error", info: "Error creating view controllers.\nSomething really weird must be going on.\n\nDo you have enough free RAM?", alertStyle: .critical)
            self.close()
            return
        }

        guard let editorVC = windowController.contentViewController as? EditorViewController else {
            self.showMsg("Error", info: "Error creating view controllers.\nSomething really weird must be going on.\n\nDo you have enough free RAM?", alertStyle: .critical)
            self.close()
            return
        }

        // Set some stuff
        editorVC.documentHandler = self
        self.editorViewController = editorVC
        self.currentWindow = windowController.window

        // Add window controller
        self.addWindowController(windowController)

        if filename != nil {
            self.editorViewController?.showLockView(self.lastComponentOfFileName, callback: { password in
                self.password = password

                do {
                    try self.read(from: self.filename!, ofType: "")
                } catch {

                }
            })
        }
    }


    override func lock(_ sender: Any?) {
        editorViewController!.showLockView(self.lastComponentOfFileName)
//        if password != nil {
//            editorViewController!.presentViewControllerAsSheet(self.unlockViewController!)
//        }
    }


    override func data(ofType typeName: String) throws -> Data {

//        throw NSError(domain: NSOSStatusErrorDomain, code: writErr, userInfo: [NSLocalizedDescriptionKey: "sddsf"])

        let jsonData = try JSONSerialization.data(withJSONObject: self.decryptedData, options:JSONSerialization.WritingOptions())

        guard let zippedData = (jsonData as NSData).gzipped() else {
            throw NSError(domain: NSOSStatusErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not compress data."])
        }

        var error: NSError?
        guard let finalData = PasswordManager.encryptData(zippedData, withPassword:self.password!, error:&error) else {
            var description = ""
            if error != nil {
                description = error!.description
            }
            throw NSError(domain: NSOSStatusErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not encrypt data: \(description)."])
        }

        // Return final data
        return finalData
    }


    override func read(from url: URL, ofType typeName: String) throws {
        if self.password == nil {
            self.filename = url
            return
        }

        try super.read(from: url, ofType: typeName)
    }


    override func read(from data: Data, ofType typeName: String) throws {
        guard let passwd = self.password else {
            return
        }

        // Try to decrypt data
        var error: NSError?
        guard let decryptedData = PasswordManager.decryptData(data, withPassword: passwd, error: &error) else {
            var description = ""
            if error != nil {
                description = error!.description
            }
            self.showMsg("Error decrypting the file!", info: "Wrong password, I guess!\n\n\(description)", alertStyle: NSAlert.Style.critical)
//            self.window!.makeKeyAndOrderFront(nil)
//            self.window!.makeFirstResponder(lockPasswordField)
            return
        }

        guard let unzippedData = (decryptedData as NSData).gunzipped() else {
            self.showMsg("Error!", info: "Could not decompress data!", alertStyle: NSAlert.Style.critical)
            return
        }

        var jsonData = DecryptedDataType()
        do {
            jsonData = try JSONSerialization.jsonObject(with: unzippedData, options: JSONSerialization.ReadingOptions.mutableContainers) as! DecryptedDataType
        } catch {
            self.showMsg("Error!", info: "Error deserializing data!", alertStyle: NSAlert.Style.critical)
//            self.window!.makeKeyAndOrderFront(nil)
//            self.window!.makeFirstResponder(lockPasswordField)
            return
        }

        self.editorViewController!.hideLockView()
//        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }


    override func save(_ sender: Any?) {
        if self.password == nil {
            self.editorViewController!.showSetPasswordView(self.lastComponentOfFileName, callback: { password in
                self.password = password
                self.editorViewController!.hideSetPasswordView()
                super.save(sender)
            })
            return
        }

        super.save(sender)
    }


//    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
//
//        savePanel.allowedFileTypes = ["cx"]
//        savePanel.treatsFilePackagesAsDirectories = true
////        if lastFilename != nil {
////            savePanel.nameFieldStringValue = lastFilename!.lastPathComponent
////        }
//
//        // Create an accessory view for password fields
//        let aView = NSView(frame: NSMakeRect(0, 0, 370, 150))
//        savePanel.accessoryView = aView
//
//        // Add password fields
//        let passwordFieldLabel = NSTextField(frame: NSMakeRect(0, aView.frame.size.height - 32, 200, 25))
//        passwordFieldLabel.stringValue = "Password:"
//        passwordFieldLabel.font = NSFont(name: "Helvetica Neue", size:13.0)
//        passwordFieldLabel.isBezeled = false
//        passwordFieldLabel.drawsBackground = false
//        passwordFieldLabel.isEditable = false
//        passwordFieldLabel.isSelectable = false
//        passwordFieldLabel.sizeToFit()
//        aView.addSubview(passwordFieldLabel)
//
//
//        let passwordField1 = NSSecureTextField(frame: NSMakeRect(passwordFieldLabel.frame.size.width + 5.0, aView.frame.size.height - 35, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
//        if #available(OSX 10.10, *) {
//            passwordField1.placeholderString = "Enter your password"
//        } else {
//            (passwordField1.cell as! NSTextFieldCell).placeholderString = "Enter your password"
//        }
//        //    passwordField1.alignment = NSCenterTextAlignment
//        aView.addSubview(passwordField1)
//
//        let passwordField2 = NSSecureTextField(frame: NSMakeRect(passwordField1.frame.origin.x, passwordField1.frame.origin.y - passwordField1.frame.size.height - 5.0, aView.frame.size.width - passwordFieldLabel.frame.size.width - 10.0, 25))
//        if #available(OSX 10.10, *) {
//            passwordField2.placeholderString = "Repeat your password"
//        } else {
//            (passwordField2.cell as! NSTextFieldCell).placeholderString = "Repeat your password"
//        }
//        //    passwordField2.alignment = NSCenterTextAlignment
//        aView.addSubview(passwordField2)
//
//        // Add description field
//        let descriptionLabel = NSTextField(frame: NSMakeRect(0, 0, aView.frame.size.width, 75))
//        descriptionLabel.stringValue = "Choose your password wisely. We recomend using passwords made of multiple words and spaces between them, making a sentence that makes sense only to you. For example: Big brown cow runs up in space 4 times in a row."
//        descriptionLabel.font = NSFont(name: "Helvetica Neue", size: 11.0)
//        descriptionLabel.cell?.wraps = true
//        descriptionLabel.isBezeled = false
//        descriptionLabel.drawsBackground = false
//        descriptionLabel.isEditable = false
//        descriptionLabel.isSelectable = false
//        aView.addSubview(descriptionLabel)
//
////        // Show the panel
////        savePanel.beginSheetModal(for: self.window!) { (result: Int) in
////            savePanel.orderOut(self)
////
////            if result == NSFileHandlingPanelOKButton {
////                if passwordField1.stringValue != passwordField2.stringValue {
////                    self.showMsg("Error!", info: "Passwords does not match.", alertStyle: NSAlertStyle.critical)
////                    return
////                }
////
////                // Not sure if this can evaluate to false
////                guard let saveUrl = savePanel.url else {
////                    return
////                }
////
////                // Warn about the empty password
////                if passwordField1.stringValue.characters.count < 1 {
////                    self.showMsg("Warning!", info:"It is generally safer to provide at least some password than no password at all.", alertStyle:NSAlertStyle.critical)
////                }
////
////                self.password = passwordField1.stringValue
////                self.lastFilename = saveUrl
////
////                if self.save(data: self.decryptedData!, toFile: self.lastFilename!) {
////                    NSDocumentController.shared().noteNewRecentDocumentURL(saveUrl)
////                    UserDefaults.standard.set(saveUrl, forKey:"LastFilename")
////                    UserDefaults.standard.synchronize()
////
////                    self.updateCurrentTitles()
////                    self.window!.isDocumentEdited = false
////                    self.documentSavedCallback()
////                    self.documentSavedCallback = {}
////                }
////            }
////        }
//
//        return true
//    }
}
