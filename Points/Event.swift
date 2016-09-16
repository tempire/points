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
    
    lazy var date: Date = {
        return Date("\(self.year)-\(self.month)-01T00:00:00Z", format: .iso8601)!
    }()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["date"]
    }
    
    class func createEvents(_ strings: [String]) throws -> [EventYear] {
        
        guard let month = Int(strings[3]),
            let id = Int(strings[0]) else {
                
                throw NSError(domain: .serializedParsing, code: .event, message: "Could not parse event: \(strings)")
        }
        
        let location = strings[2]
        let name = strings[1]

        return strings[4].components(separatedBy: ",").flatMap {
            guard let year = Int($0) else {
                return .none
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
        
        self.id = [String(event.id), String(month), String(year)].joined(separator: "^")
        self.month = month
        self.year = year
        self.event = event
    }
    
    var shortDateString: String {
        return String(date.shortMonthToString() + "\n" + String(date.year()))
    }
    
    var divisions:
}

struct Division {
    var finalists: [Competition]
    var placements: [Placement]
    
    struct Placement {
        var partners: [Competition]
        
        // Optionals - allow for missing data and/or multiple partners for 3-for-alls and such
        var lead: Competition?
        var follow: Competition?
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
