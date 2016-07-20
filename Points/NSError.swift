//
//  NSError.swift
//  Points
//
//  Created by Glen Hinkle on 7/17/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension NSError {
    enum Domain {
        
        enum Code {
            case Role
            case Result
            case Strings
            case SectionTitle
            case Dancer
            case Competition
            case Event
            case JSON(Int)
            case Timeout(NSTimeInterval)
            
            var value: Int {
                switch self {
                case Role: return 0
                case Result: return 1
                case Strings: return 2
                case SectionTitle: return 3
                case Dancer: return 4
                case Competition: return 5
                case Event: return 6
                case JSON(let code): return 100 + code
                case Timeout(_): return 7
                }
            }
        }
        
        case SerializedParsing
        case JSON
        case Network
        
        var description: String {
            
            switch self {
                
            case .SerializedParsing(_):
                return "SerializedParsing"
                
            case .JSON:
                return "JSON"
                
            case .Network:
                return "Network"
            }
        }
    }
    
    convenience init(domain: Domain, code: Domain.Code, message: String) {
        
        self.init(
            domain: domain.description,
            code: code.value,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}