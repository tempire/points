//
//  Event.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import RealmSwift

class Event: Object, StringImport {
    dynamic var id: Int = 0
    dynamic var name: String = ""
    dynamic var location: String?
    dynamic var month: Int = 0
    dynamic var year: Int = 0
    
    lazy var date: NSDate = {
        return NSDate("\(self.year)-\(self.month)-01T00:00:00Z", format: .ISO8601)!
    }()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["date"]
    }
    
    convenience required init(strings: [String]) throws {
        self.init()
        
        guard let month = Int(strings[0]),
            year = Int(strings[1]),
            id = Int(strings[2]) else {
                
                throw NSError(domain: .SerializedParsing, code: .Event, message: "Could not parse event: \(strings)")
        }
        
        self.id = id
        self.month = month
        self.year = year + 2000
        self.location = strings[3]
        self.name = strings[4]
    }
}
