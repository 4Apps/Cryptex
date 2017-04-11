//
//  KeyChain.swift
//  Cryptex
//
//  Created by Gints Murans on 09.08.16.
//  Copyright © 2016. g. 4Apps. All rights reserved.
//

import Foundation
import Security


public enum ResultCode : Int32, CustomStringConvertible {

    case success                = 0
    case unimplemented          = -4
    case param                  = -50
    case allocate               = -108
    case notAvailable           = -25291
    case authFailed             = -25293
    case duplicateItem          = -25299
    case itemNotFound           = -25300
    case interactionNotAllowed  = -25308
    case decode                 = -26275
    // =============== Warning: -25243 is undocumented by Apple ===============
    case noAccessForItem        = -25243

    public var description : String {
        get {
            switch(self) {
            case .success:
                return "No error"
            case .unimplemented:
                return "Function or operation not implemented"
            case .param:
                return "One or more parameters passed to the function were not valid"
            case .allocate:
                return "Failed to allocate memory"
            case .notAvailable:
                return "No trust results are available"
            case .authFailed:
                return "Authorization/Authentication failed"
            case .duplicateItem:
                return "The item already exists"
            case .itemNotFound:
                return "The item cannot be found"
            case .interactionNotAllowed:
                return "Interaction with the Security Server is not allowed"
            case .decode:
                return "Unable to decode the provided data"
            case .noAccessForItem:
                return "No Access For Item"
            }
        }
    }
}


func keyChain_setString(let key: String!, let value: String?, let service: String = "MY_SERVICE") -> ResultCode? {
    var data: NSData = NSData();
    if value != nil {
        data = value!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!;
    }

    let attributes: NSMutableDictionary = NSMutableDictionary(
        objects: [
            kSecClassGenericPassword,
            service,
            key,
            data,
            kCFBooleanTrue,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ],
        forKeys: [
            String(kSecClass),
            String(kSecAttrService),
            String(kSecAttrGeneric),
            String(kSecValueData),
            String(kSecUseAuthenticationUI),
            String(kSecAttrAccessible)
        ]);

    var status: OSStatus = SecItemAdd(attributes as CFDictionaryRef, nil);
    if status == errSecSuccess {
        print("errSecSuccess")

        return nil;
    }

    // Update
    if status == errSecDuplicateItem {
        let query: NSMutableDictionary = NSMutableDictionary(
            objects: [
                kSecClassGenericPassword,
                service,
                key,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                "To update your password, please authenticate using TouchID."
            ],
            forKeys: [
                String(kSecClass),
                String(kSecAttrService),
                String(kSecAttrGeneric),
                String(kSecAttrAccessible),
                String(kSecUseOperationPrompt)
            ]);

        let attributes: NSMutableDictionary = NSMutableDictionary(
            objects: [
                data
            ],
            forKeys: [
                String(kSecValueData)
            ]);

        status = SecItemUpdate(query, attributes);

        if status == errSecSuccess {
            return nil
        }

        let result = ResultCode(rawValue: status)
        return result
    }


    let result = ResultCode(rawValue: status)
    return result
}


func keyChain_getString(let key: String!, let service: String = "MY_SERVICE") -> String? {
    let query: NSMutableDictionary = NSMutableDictionary(
        objects: [
            kSecClassGenericPassword,
            service,
            key,
            kCFBooleanTrue,
            kSecMatchLimitOne,
            "To retrieve your password, please authenticate using TouchID."
        ],
        forKeys: [
            String(kSecClass),
            String(kSecAttrService),
            String(kSecAttrGeneric),
            String(kSecReturnData),
            String(kSecMatchLimit),
            String(kSecUseOperationPrompt)
        ]);

    var dataTypeRef: AnyObject?;
    let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef);

    if status == errSecSuccess {
        if dataTypeRef != nil {
            let resultData = dataTypeRef as! NSData
            let result = String(data: resultData, encoding: NSUTF8StringEncoding)

            return result
        }
    }

    let result = ResultCode(rawValue: status)
    print(result?.description)

    return nil;
}


func keyChain_deleteItem(let key: String!, let service: String = "MY_SERVICE") -> Bool {
    let query: NSMutableDictionary = NSMutableDictionary(
        objects: [
            kSecClassGenericPassword,
            service,
            key,
            "To delete your password from keychain, please authenticate using TouchID."
        ],
        forKeys: [
            String(kSecClass),
            String(kSecAttrService),
            String(kSecAttrGeneric),
            String(kSecUseOperationPrompt)
        ]);

    let status: OSStatus = SecItemDelete(query);

    if status == errSecSuccess {
        return true
    }

    let result = ResultCode(rawValue: status)
    print(result?.description)
    
    return false;
}
