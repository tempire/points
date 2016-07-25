//
//  Event.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import RealmSwift

class EventYear: Object {
    dynamic var id: String = ""
    dynamic var month: Int = 0
    dynamic var year: Int = 0
    dynamic var event: Event!
    
    let competitions = LinkingObjects(fromType: Competition.self, property: "eventYear")
    
    lazy var date: NSDate = {
        return NSDate("\(self.year)-\(self.month)-01T00:00:00Z", format: .ISO8601)!
    }()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["date"]
    }
    
    class func createEvents(strings: [String]) throws -> [EventYear] {
        
        guard let month = Int(strings[3]),
            id = Int(strings[0]) else {
                
                throw NSError(domain: .SerializedParsing, code: .Event, message: "Could not parse event: \(strings)")
        }
        
        let location = strings[2]
        let name = strings[1]

        return strings[4].componentsSeparatedByString(",").flatMap {
            guard let year = Int($0) else {
                return .None
            }
            
            return EventYear(
                month: month,
                year: year + 2000,
                event: Event(id: id, name: name, location: location)
            )
        }
    }
    
    convenience required init(month: Int, year: Int, event: Event) {
        self.init()
        
        self.id = [String(event.id), String(month), String(year)].joinWithSeparator("^")
        self.month = month
        self.year = year
        self.event = event
    }
}

class Event: Object {
    dynamic var id: Int = 0
    dynamic var name: String = ""
    dynamic var location: String?
    
    let years = LinkingObjects(fromType: EventYear.self, property: "event")
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience required init(id: Int, name: String, location: String?) {
        self.init()
        
        self.id = id
        self.name = name
        self.location = location
    }
}
