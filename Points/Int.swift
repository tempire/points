//
//  Int.swift
//  Points
//
//  Created by Glen Hinkle on 7/25/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension Int {
    
    init?(_ string: String?) {
        
        guard let rawValue = string, int = Int(rawValue) else {
            return nil
        }
        
        self = int
    }
}