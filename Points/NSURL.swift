//
//  NSURL.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension NSURL {
    
    func URL(path: String, parameters: [String:AnyObject]) -> NSURL {
        let comp = NSURLComponents(string: URLByAppendingPathComponent(path).absoluteString)!
        
        comp.queryItems = Array(parameters.keys).flatMap {
            guard let value = parameters[$0] else {
                return .None
            }
            
            return NSURLQueryItem(name: $0, value: "\(value)")
        }
        
        return comp.URL!
    }
}