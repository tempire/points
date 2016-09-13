//
//  NSURLRequest.swift
//  Pods
//
//  Created by Glen Hinkle on 7/17/16.
//
//

import Foundation

extension URLRequest {
    
    func header(_ header: Header) -> Header? {
        guard let value = allHTTPHeaderFields?[header.name] else {
            return .none
        }
        
        switch header {
        case .beacon(_):
            return .beacon(UUID(uuidString: value)!)
            
        case .date(_):
            return .date(Date(value, format: .iso8601)!)
            
        case .responseTime(_):
            return .responseTime(1)
            
        case .basicAuthorization(_):
            return .none
        }
    }
}
