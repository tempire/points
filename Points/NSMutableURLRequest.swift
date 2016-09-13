//  NSMutableURLRequest.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

enum Header {
    case beacon(UUID)
    case date(Foundation.Date)
    case responseTime(TimeInterval)
    case basicAuthorization(username: String, password: String)
    
    var name: String {
        switch self {
        case .beacon(_):
            return "X-Beacon"
            
        case .date(_):
            return "X-Date"
            
        case .responseTime(_):
            return "X-ResponseTime"
            
        case .basicAuthorization(_):
            return "Authorization"
        }
    }
}

extension NSMutableURLRequest {
    
    public enum Method: String {
        case GET
        case POST
    }
    
    convenience init(url: URL, method: Method, parameters: [String:AnyObject] = [:]) {
        self.init()
        
        self.url = url
        httpMethod = method.rawValue
        setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        addFormParameters(parameters)
    }
    
    func addFormParameters(_ parameters: [String:AnyObject]) {
        var comp = URLComponents(string: "")! //URLByAppendingPathComponent(path).absoluteString)!
        
        comp.queryItems = Array(parameters.keys).flatMap {
            guard let value = parameters[$0] else {
                return .none
            }
            
            return URLQueryItem(name: $0, value: "\(value)")
        }
        
        httpBody = comp.url?.query?.data(using: String.Encoding.utf8)
    }

    func setHeader(_ header: Header) {
        var value = ""
        
        switch header {
        case let .beacon(beacon):
            value = beacon.uuidString
            
        case let .date(date):
            value = date.toString(format: .iso8601)
            
        case let .responseTime(interval):
            value = String(interval)
            
        case let .basicAuthorization(credentials):
            let encoded = "\(credentials.username):\(credentials.password)".data(using: String.Encoding.utf8)?.base64EncodedString(options: []) ?? ""
            value = "Basic \(encoded)"
        }
        
        addValue(value, forHTTPHeaderField: header.name)
    }
}
