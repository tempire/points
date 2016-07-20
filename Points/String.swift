//
//  String.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension String {
    
    var trim: String? {
        return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty ? .None : self
    }
}