//
//  LockedViewController.swift
//  Cryptex
//
//  Created by Gints Murans on 09.08.16.
//  Copyright © 2016. g. 4Apps. All rights reserved.
//

import UIKit
import LocalAuthentication
import PasswordManagerIOS


class LockViewController: UINavigationController {

    @IBAction func test(let sender: UIButton) {

        print("\n")

        let data = "SECURE ME !!!".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

        let encData1 = PasswordManager.hashWhirlpool(data!)
        print("Whirlpool: Data Length: \(encData1?.length); Data: \(encData1)")

        let encData2 = PasswordManager.hashSHA256(data!)
        print("SHA256: Data Length: \(encData2?.length); Data: \(encData2)")

        PasswordManager.encryptData(data!, withPassword: "sdgfsdgd", error: nil)

        print("\n")

//        let status = keyChain_setString("Password", value: "JKASHAKJSHOSJHA")
//        if status == nil {
//            print("Password was succeffully set!")
//        } else {
//            print("Error: \(status?.description)")
//        }

//        let password = keyChain_getString("Password")
//        print(password)

//        keyChain_deleteItem("Password")

    }

}