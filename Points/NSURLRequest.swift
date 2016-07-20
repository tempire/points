//
//  NSURLRequest.swift
//  Pods
//
//  Created by Glen Hinkle on 7/17/16.
//
//

import Foundation

extension NSURLRequest {
    
    func header(header: Header) -> Header? {
        guard let value = allHTTPHeaderFields?[header.name] else {
            return .None
        }
        
        switch header {
        case .Beacon(_):
            return .Beacon(NSUUID(UUIDString: value)!)
            
        case .Date(_):
            return .Date(NSDate(value, format: .ISO8601)!)
            
        case .ResponseTime(_):
            return .ResponseTime(1)
            
        case .BasicAuthorization(_):
            return .None
        }
    }
}