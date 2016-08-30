//
//  NSIndexPath.swift
//  Points
//
//  Created by Glen Hinkle on 8/29/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension NSIndexPath {
    
    var nextRow: NSIndexPath {
        return NSIndexPath(forRow: row + 1, inSection: section)
    }
}