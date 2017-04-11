//
//  SplitViewController.swift
//  Cryptex
//
//  Created by Gints Murans on 09.08.16.
//  Copyright © 2016. g. 4Apps. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {


    override func viewDidAppear(animated: Bool) {
        if 1 == 1 {
            self.performSegueWithIdentifier("LockSegue", sender: self)
//            let lockViewController = self.storyboard!.instantiateViewControllerWithIdentifier("LockViewController")
//            self.presentViewController(lockViewController, animated: false, completion: nil)
        }
    }

}