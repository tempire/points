//
//  UIViewController.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func performSegueWithVC<A: UIViewController>(type: A.Type, sender: AnyObject?) {
        performSegueWithIdentifier("\(A.self)", sender: sender)
    }
    
    func replaceRootVC(vc: UIViewController, completion: (Void->Void)?) {
        guard let window = UIApplication.sharedApplication().keyWindow, rootVC = window.rootViewController else {
            return
        }
        
        let snapshot = window.snapshotViewAfterScreenUpdates(true)
        vc.view.addSubview(snapshot)
        
        window.rootViewController = vc
        window.makeKeyAndVisible()
        
        UIView.animateWithDuration(0.3,
                                   animations: {
                                    snapshot.layer.opacity = 0 },
                                   completion: { finished in
                                    rootVC.dismissViewControllerAnimated(false) {
                                        snapshot.removeFromSuperview()
                                        rootVC.view.removeFromSuperview()
                                        completion?()
                                    }
            }
        )
    }
}