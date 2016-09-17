//
//  WSDC.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CloudKit

func ==(lhs: WSDC.Event, rhs: WSDC.Event) -> Bool { return rhs.hashValue == lhs.hashValue }
func ==(lhs: WSDC.Competition.Result, rhs: WSDC.Competition.Result) -> Bool { return rhs.hashValue == lhs.hashValue }
func <(lhs: WSDC.DivisionName, rhs: WSDC.DivisionName) -> Bool { return rhs.hashValue < lhs.hashValue }

class WSDC {
    
    struct SearchResults: JSONStruct {
        var competitors: [SearchResult]
        
        init(json: JSONObject) throws {
            try competitors = json.value("names")
        }
        
        var json: JSONObject {
            return [:]
        }
    }
    
    struct SearchResult: JSONStruct {
        var id: Int
        var firstName: String
        var lastName: String
        var wsdcId: Int
        
        init(json: JSONObject) throws {
            try id = json.value("id")
            try firstName = json.value("first_name")
            try lastName = json.value("last_name")
            try wsdcId = json.value("wscid")
        }
        
        var json: JSONObject {
            return [
                "id": id as AnyObject,
                "firstName": firstName as AnyObject,
                "lastName": lastName as AnyObject,
                "wsdcId": wsdcId as AnyObject,
            ]
        }
    }
    
    struct Competitor: JSONStruct {
        var id: Int
        var wsdcId: Int
        var firstName: String
        var lastName: String
        var divisions: [Division]
        
        init(json: JSONObject) throws {
            try id = json.value("dancer.id")
            try wsdcId = json.value("dancer.wscid")
            try firstName = json.value("dancer.first_name")
            try lastName = json.value("dancer.last_name")
            
            if let json = json["placements"] as? JSONObject, let _ = json["West Coast Swing"] {
                divisions = try json.value("West Coast Swing")
            }
            else {
                divisions = []
            }
        }
        
        var json: JSONObject {
            return [
                "id": id as AnyObject,
                "wsdcId": wsdcId as AnyObject,
                "first_name": firstName as AnyObject,
                "last_name": lastName as AnyObject,
                "placements": [ 
                    "West Coast Swing": divisions.map { $0.json }
                ] as AnyObject
            ]
        }
        
        var keys = [
            "id", "wsdcId", "firstName", "lastName"
        ]
        
        var serialized: String {
            return [
                "\(wsdcId)",
                firstName,
                lastName
                ].joined(separator: "^")
        }
    }
    
    struct Division: JSONStruct {
        var competitions: [Competition]
        var name: DivisionName
        var totalPoints: Int
        
        
        init(json: JSONObject) throws {
            try competitions = json.value("competitions")
            try name = json.value("division.abbreviation")
            try totalPoints = json.value("total_points")
        }
        
        var json: JSONObject {
            return [
                "competitions": competitions.map { $0.json } as [Any],
                "name": name.description,
                "total_points": totalPoints
            ]
        }
    }
    
    enum DivisionName: String, JSONValueType, Comparable {
        case JRS = "Juniors"
        case SPH = "Sophisticated"
        case MSTR = "Masters"
        case NEW = "Newcomer"
        case NOV = "Novice"
        case INT = "Intermediate"
        case ADV = "Advanced"
        case PRO = "Professional"
        case TCH = "Teacher"
        case ALS = "All-Star"
        case INV = "Invitational"
        case CHMP = "Champion"
        
        static var values = [ CHMP, INV, ALS, ADV, INT, MSTR, SPH, NOV, JRS, NEW, JRS, PRO, TCH ]
        
        static var rankOrder: [DivisionName:Int] {
            
            return [NEW, NOV, INT, ADV, ALS, CHMP].enumerated().reduce([:]) { tmp, tuple in
                var dict = tmp
                dict[tuple.element] = tuple.offset
                return dict
            }
        }
        
        static var displayOrder: [DivisionName:Int] {
            return DivisionName.values.enumerated().reduce([:]) { tmp, tuple in
                var dict = tmp
                dict[tuple.element] = tuple.offset
                return dict
            }
        }
        
        var displayOrder: Int {
            return DivisionName.displayOrder[self] ?? 0
        }
        
        var pointsForNextRank: Int? {
            switch self {
            case .NOV:
                return 15
            case .INT:
                return 30
            case .ADV:
                return 45
            default:
                return .none
            }
        }
        
        var nextRank: DivisionName? {
            switch self {
            case .NOV:
                return .INT
            case .INT:
                return .ADV
            case .ADV:
                return .ALS
            default:
                return .none
            }
        }
        
        var description: String {
            return rawValue
        }
        
        var abbreviation: String {
            return "\(self)"
        }
        
        var serialized: Int {
            switch self {
            case .JRS: return 0
            case .SPH: return 1
            case .MSTR: return 2
            case .NEW: return 3
            case .NOV: return 4
            case .INT: return 5
            case .ADV: return 6
            case .PRO: return 7
            case .TCH: return 8
            case .ALS: return 9
            case .INV: return 10
            case .CHMP: return 11
            }
        }
        
        init?(description: String?) {
            guard let rawValue = description, let name = DivisionName(rawValue: rawValue) else {
                return nil
            }
            
            self = name
        }
        
        init?(abbreviation: String?) {
            switch abbreviation {
            case "JRS"?: self = .JRS
            case "INV"?: self = .INV
            case "CHMP"?: self = .CHMP
            case "ALS"?: self = .ALS
            case "SPH"?: self = .SPH
            case "MSTR"?: self = .MSTR
            case "TCH"?: self = .TCH
            case "NEW"?: self = .NEW
            case "NOV"?: self = .NOV
            case "INT"?: self = .INT
            case "ADV"?: self = .ADV
            case "PRO"?: self = .PRO
            default: return nil
            }
        }
        
        static func JSONValue(_ object: Any) throws -> DivisionName {
            if let name = DivisionName(abbreviation: object as? String) {
                return name
            }
            
            throw JSONError.typeMismatch(expected: self, actual: type(of: object))
        }
    }
    
    struct Competition: JSONStruct {
        var points: Int
        var result: Result
        var role: Role
        var event: Event
        
        enum Role: String, JSONValueType {
            case Lead
            case Follow
            
            var description: String {
                return rawValue
            }
            
            var color: UIColor {
                switch self {
                case .Lead: return UIColor.lead
                case .Follow: return UIColor.follow
                }
            }
            
            var tinyRaw: String {
                switch self {
                case .Lead: return "l"
                case .Follow: return "f"
                }
            }
            
            init?(tinyRaw: String) {
                switch tinyRaw {
                case "l":
                    self = .Lead
                case "f":
                    self = .Follow
                default:
                    return nil
                }
            }
            
            init?(_ value: String) {
                switch value {
                case "leader": self = .Lead
                case "follower": self = .Follow
                default: return nil
                }
            }
            
            static func JSONValue(_ object: Any) throws -> Role {
                if let string = object as? String, let role = Role(string) {
                    return role
                }
                
                throw JSONError.typeMismatch(expected: self, actual: type(of: object))
            }
        }
        
        enum Result: JSONValueType, Hashable {
            var hashValue: Int {
                return tinyRaw.hashValue
            }
            
            case placement(Int)
            case final
            
            init(string: String) throws {
                if string == "F" {
                    self = .final
                }
                else if let int = Int(string) {
                    self = .placement(int)
                }
                else {
                    throw NSError(domain: "", code: 0, userInfo: [:])
                }
            }
            
            var description: String {
                switch self {
                case let .placement(int):
                    return String(int) + ext + " Place"
                case .final:
                    return "Finals"
                }
            }
            
            var tinyRaw: String {
                
                switch self {
                    
                case let .placement(int):
                    return "\(int)"
                    
                case .final:
                    return "F"
                }
            }
            
            var ext: String {
                switch self {
                case let .placement(int):
                    switch int {
                    case 1: return "st"
                    case 2: return "nd"
                    case 3: return "rd"
                    case 4, 5: return "th"
                        
                    default:
                        return ""
                    }
                default: return ""
                }
            }
            
            var displayOrder: Int {
                
                switch self {
                    
                case .placement(let int):
                    return int
                    
                case .final:
                    return 6
                }
            }
            
            static func JSONValue(_ object: Any) throws -> Result {
                guard let string = object as? String else {
                    throw JSONError.typeMismatch(expected: self, actual: type(of: object))
                }
                
                if let int = Int(string) {
                    return .placement(int)
                }
                else if string == "F" {
                    return .final
                }
                
                throw JSONError.typeMismatch(expected: self, actual: type(of: object))
            }
        }
        
        init(json: JSONObject) throws {
            try points = json.value("points")
            try result = json.value("result")
            try role = json.value("role")
            try event = json.value("event")
        }
        
        var json: JSONObject {
            return [
                "points": points as AnyObject,
                "result": result.description as AnyObject,
                "role": role.description as AnyObject,
                "event": event.json as AnyObject
            ]
        }
        
        func serialized(withId id: Int, andDivision divisionName: DivisionName) -> String {
            return [
                "\(id)",
                divisionName.abbreviation,
                "\(points)",
                result.tinyRaw,
                role.tinyRaw,
                "\(event.id)",
                "\(event.date.year() - 2000)"
            ].joined(separator: "^")
        }
    }
    
    struct Event: JSONStruct, Hashable {
        var hashValue: Int { return id.hashValue + date.hashValue }
        
        var date: Date
        var id: Int
        var location: String
        var name: String
        //var url: URL?
        
        init(json: JSONObject) throws {
            try date = json.value("date")
            try id = json.value("id")
            try location = json.value("location")
            try name = json.value("name")
            //try url = json.value("url")
        }
        
        var json: JSONObject {
            var dict: JSONObject = [
                "date": date.toString(format: .wsdcEventMonth) as AnyObject,
                "id": id as AnyObject,
                "location": location as AnyObject,
                "name": name as AnyObject
            ]

            //if let url = url {
            //    dict["url"] = url.absoluteString as AnyObject?
            //}
            
            return dict
        }
        
        var serialized: String {
            return [
                "\(date.month())",
                "\(date.year() - 2000)",
                "\(id)",
                location,
                name,
                ].joined(separator: "^")
        }
    }
}
