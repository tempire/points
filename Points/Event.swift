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
    
    var divisions: [WSDC.DivisionName:Division] {
        var divisions: [WSDC.DivisionName:Division] = [:]

        competitions.forEach { competition in
            var division = divisions[competition.divisionName] ?? Division(placements: [], finalists: [])
                
            switch competition.result {
                
            case .placement(let placementIndex):
                division.placements[placementIndex]?.partners.append(competition)
                
            case .final:
                division.finalists.append(competition)
            }
        }
        
        return divisions
    }

    struct Division {
        var placements: [Placement?]
        var finalists: [Competition]
        
        func index(index: Int) -> Placement? {
            return placements[index]
        }
        
        var first: Placement? {
            return placements[0]
        }
        
        var second: Placement? {
            return placements[1]
        }
        
        var third: Placement? {
            return placements[2]
        }
        
        var fourth: Placement? {
            return placements[3]
        }
        
        var fifth: Placement? {
            return placements[4]
        }
        
        struct Placement {
            var partners: [Competition]
            
            var lead: Competition? {
                return partners.filter { $0.role == .Lead }.first
            }

            var follow: Competition? {
                return partners.filter { $0.role == .Follow }.first
            }
        }
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
