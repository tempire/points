//  NSMutableURLRequest.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

enum Header {
    case Beacon(beacon: String)
    case Date(date: NSDate)
    case ResponseTime(interval: NSTimeInterval)
    case BasicAuthorization(credentials: (username: String, password: String))
    
    var name: String {
        switch self {
        case .Beacon(_):
            return "X-Beacon"
            
        case .Date(_):
            return "X-Date"
            
        case .ResponseTime(_):
            return "X-ResponseTime"
            
        case .BasicAuthorization(_):
            return "Authorization"
        }
    }
}

extension NSMutableURLRequest {
    
    public enum Method: String {
        case GET
        case POST
    }
    
    convenience init(url: NSURL, method: Method, parameters: [String:AnyObject] = [:]) {
        self.init()
        
        URL = url
        HTTPMethod = method.rawValue
        setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        addFormParameters(parameters)
    }
    
    func addFormParameters(parameters: [String:AnyObject]) {
        let comp = NSURLComponents(string: "")! //URLByAppendingPathComponent(path).absoluteString)!
        
        comp.queryItems = Array(parameters.keys).flatMap {
            guard let value = parameters[$0] else {
                return .None
            }
            
            return NSURLQueryItem(name: $0, value: "\(value)")
        }
        
        HTTPBody = comp.URL?.query?.dataUsingEncoding(NSUTF8StringEncoding)
    }

    func setHeader(header: Header) {
        var value = ""
        
        switch header {
        case let .Beacon(beacon):
            value = beacon
            
        case let .Date(date):
            value = date.toString(format: .ISO8601)
            
        case let .ResponseTime(interval):
            value = String(interval)
            
        case let .BasicAuthorization(credentials):
            let encoded = "\(credentials.username):\(credentials.password)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([]) ?? ""
            value = "Basic \(encoded)"
        }
        
        addValue(value, forHTTPHeaderField: header.name)
    }
}