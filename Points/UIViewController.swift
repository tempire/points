//
//  UIViewController.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboardSegue {
    
    enum Identifier: String {
        case Partner
        
        init?(_ rawValue: String?) {
            guard let rawValue = rawValue, let identifier = Identifier(rawValue: rawValue) else {
                return nil
            }
            
            self = identifier
        }
    }
}


extension UIViewController {
    
    func performSegueWithVC<A: UIViewController>(_ type: A.Type, sender: AnyObject?) {
        performSegue(withIdentifier: "\(A.self)", sender: sender)
    }
    
    func performSegueWithIdentifier(_ identifier: UIStoryboardSegue.SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: "\(identifier)", sender: sender)
    }
    
    func replaceRootVC(_ vc: UIViewController, completion: ((Void)->Void)?) {
        guard let window = UIApplication.shared.keyWindow, let rootVC = window.rootViewController else {
            return
        }
        
        let snapshot = window.snapshotView(afterScreenUpdates: true)
        vc.view.addSubview(snapshot!)
        
        window.rootViewController = vc
        window.makeKeyAndVisible()
        
        UIView.animate(withDuration: 0.3,
                                   animations: {
                                    snapshot?.layer.opacity = 0 },
                                   completion: { finished in
                                    rootVC.dismiss(animated: false) {
                                        snapshot?.removeFromSuperview()
                                        rootVC.view.removeFromSuperview()
                                        completion?()
                                    }
            }
        )
    }
}
