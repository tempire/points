//
//  NSIndexPath.swift
//  Points
//
//  Created by Glen Hinkle on 8/29/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension IndexPath {
    
    var nextRow: IndexPath {
        return IndexPath(row: row + 1, section: section)
    }
}
