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
    func dequeueCell<A: UITableViewCell>(_ type: A.Type, for indexPath: IndexPath) -> A {
        return dequeueReusableCell(withIdentifier: String(describing: A.self), for: indexPath) as! A
    }
    
    func reloadDataWithDissolve(_ completion: ((Bool)->Void)? = .none) {
        reloadData(0.15, completion: completion)
    }
    
    func reloadData(_ duration: TimeInterval, completion: ((Bool)->Void)?) {
        UIView.transition(with: self,
                                  duration: duration,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.reloadData() },
                                  completion: completion
        )
    }
}
