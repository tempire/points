//
//  NSPredicate.swift
//  Points
//
//  Created by Glen Hinkle on 7/4/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension NSPredicate {
    static var all: NSPredicate {
        return NSPredicate(format: "TRUEPREDICATE")
    }
}