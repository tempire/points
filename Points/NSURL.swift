//
//  NSURL.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension Foundation.URL {
    
    func URL(_ path: String, parameters: [String:AnyObject]) -> Foundation.URL {
        var comp = URLComponents(string: appendingPathComponent(path).absoluteString)!
        
        comp.queryItems = Array(parameters.keys).flatMap {
            guard let value = parameters[$0] else {
                return .none
            }
            
            return URLQueryItem(name: $0, value: "\(value)")
        }
        
        return comp.url!
    }
}
