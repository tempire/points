//
//  UITableView.swift
//  Points
//
//  Created by Glen Hinkle on 7/17/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func dequeueCell<A: UITableViewCell>(type: A.Type, for indexPath: NSIndexPath) -> A {
        return dequeueReusableCellWithIdentifier("\(A.self)", forIndexPath: indexPath) as! A
    }
    
    func reloadDataWithDissolve(completion: (Bool->Void)? = .None) {
        reloadData(0.15, completion: completion)
    }
    
    func reloadData(duration: NSTimeInterval, completion: (Bool->Void)?) {
        UIView.transitionWithView(self,
                                  duration: duration,
                                  options: .TransitionCrossDissolve,
                                  animations: {
                                    self.reloadData() },
                                  completion: completion
        )
    }
}