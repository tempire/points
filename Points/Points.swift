//
//  Database.swift
//  Points
//
//  Created by Glen Hinkle on 7/15/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

//func ==(lhs: Points.Event, rhs: Points.Event) -> Bool { return rhs.hashValue == lhs.hashValue }

class Points {
    static var sharedInstance = Points()
    
    private var _dancers: [Dancer] = []
    private var _competitions: [Competition] = []
    private var _events: [Event] = []
    
    struct Dancer {
        let id: Int
        let fname: String
        let lname: String
    }
    
    struct Competition {
        let wsdcId: Int
        let divisionName: WSDC.DivisionName
        let points: Int
        let result: Result
        let role: Role
        let eventId: Int
        let year: Int
    }
    
    struct Event {
        let month: Int
        let year: Int
        let id: Int
        let location: String
        let name: String
    }
    
    enum Role {
        case Lead
        case Follow
        
        init(_ string: String) throws {
            
            if string == "l" {
                self = .Lead
            }
            else if string == "f" {
                self = .Follow
            }
            else {
                throw NSError(domain: "", code: 0, userInfo: [:])
            }
        }
    }
    
    enum Result {
        case Placement(Int)
        case Final
        
        var description: String {
            switch self {
            case let .Placement(int):
                return "\(int)"
            case .Final:
                return "F"
            }
        }
        
        var ext: String {
            switch self {
                
            case let .Placement(int):
                switch int {
                case 1: return "st"
                case 2: return "nd"
                case 3: return "rd"
                case 4, 5: return "th"
                    
                default:
                    return ""
                }
                
            default:
                return ""
            }
        }
        
        init(_ string: String) throws {
            
            if string.uppercaseString == "F" {
                self = .Final
            }
            else if let int = Int(string) {
                self = .Placement(int)
            }
            else {
                throw NSError(domain: "", code: 0, userInfo: [:])
            }
        }
    }

    class func setup(data: NSData) throws {
        let uncompressed = try BZipCompression.decompressedDataWithData(data)
        
        guard let dict = NSKeyedUnarchiver.unarchiveObjectWithData(uncompressed) as? [String:[String]],
            dancersArray = dict["dancers"],
            competitionsArray = dict["competitions"],
            eventsArray = dict["events"] else {
                throw NSError(domain: "", code: 0, userInfo: [:])
        }
        
        Points.sharedInstance._dancers = try dancersArray.map { dancer -> Dancer in
            let array = dancer.componentsSeparatedByString("^")
            
            if let id = Int(array[0]) {
                return Dancer(
                    id: id, fname: array[1], lname: array[2]
                )
            }
            
            throw NSError(domain: "", code: 0, userInfo: [:])
        }
        
        Points.sharedInstance._competitions = try competitionsArray.map { competition -> Competition in
            let array = competition.componentsSeparatedByString("^")
            
            guard let wsdcId = Int(array[0]),
                divisionName = WSDC.DivisionName(array[1]),
                points = Int(array[2]),
                eventId = Int(array[5]),
                year = Int(array[6]) else {
                    throw NSError(domain: "", code: 0, userInfo: [:])
            }
        
            return Competition(
                wsdcId: wsdcId,
                divisionName: divisionName,
                points: points,
                result: try Result(array[3]),
                role: try Role(array[4]),
                eventId: eventId,
                year: year
            )
        }
        
        Points.sharedInstance._events = try eventsArray.map { event in
            let array = event.componentsSeparatedByString("^")
            
            if let month = Int(array[0]),
                year = Int(array[1]),
                eventId = Int(array[2]) {
                
                return Event(
                    month: month,
                    year: year+2000,
                    id: eventId,
                    location: array[3],
                    name: array[4]
                )
            }
            
            throw NSError(domain: "", code: 0, userInfo: [:])
        }
    }
    
    class func competitions(for id: Int) -> [Competition] {
        return Points.sharedInstance._competitions.filter { c in
            return c.wsdcId == id
        }
    }
    
    class func competitions(for id: Int, division divisionName: WSDC.DivisionName) -> [Competition] {
        return Points.sharedInstance._competitions.filter { c in
            return c.wsdcId == id && c.divisionName == divisionName
        }
    }
    
    var events: [Event] {
        return Points.sharedInstance._events
    }
}