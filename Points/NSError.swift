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
            case role
            case result
            case strings
            case sectionTitle
            case dancer
            case competition
            case event
            case json(Int)
            case timeout(TimeInterval)
            
            var value: Int {
                switch self {
                case .role: return 0
                case .result: return 1
                case .strings: return 2
                case .sectionTitle: return 3
                case .dancer: return 4
                case .competition: return 5
                case .event: return 6
                case .json(let code): return 100 + code
                case .timeout(_): return 7
                }
            }
        }
        
        case serializedParsing
        case json
        case network
        
        var description: String {
            
            switch self {
                
            case .serializedParsing(_):
                return "SerializedParsing"
                
            case .json:
                return "JSON"
                
            case .network:
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
