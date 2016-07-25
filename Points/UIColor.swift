//
//  UIColor.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    static var lead: UIColor {
        return UIColor(red: 0.529, green: 0.808, blue: 0.922, alpha: 1.00)
    }
    
    static var follow: UIColor {
        return UIColor(red: 0.980, green: 0.502, blue: 0.447, alpha: 1.00)
    }
    
    struct charcoal {
        static let light = UIColor(red: 0.333, green: 0.333, blue: 0.333, alpha: 1.00)
        static let dark = UIColor(red: 0.102, green: 0.102, blue: 0.106, alpha: 1.00)
    }
}