//
//  Competition.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import RealmSwift

protocol StringImport {
    init(strings: [String]) throws
}

extension StringImport {
    
    init(_ string: String) throws {
        try self.init(strings: string.componentsSeparatedByString("^"))
    }
}

class Competition: Object, StringImport {
    dynamic var _id: String = ""
    dynamic var wsdcId: Int = 0
    dynamic var points: Int = 0
    dynamic private var _divisionName: String = ""
    dynamic private var _result: String = ""
    dynamic private var _role: String = ""
    dynamic private var eventId: Int = 0
    dynamic private var year: Int = 0
    
    let dancer = LinkingObjects(fromType: Dancer.self, property: "competitions")
    
    var divisionName: WSDC.DivisionName {
        get {
            return WSDC.DivisionName(abbreviation: _divisionName)!
        }
        set {
            _divisionName = newValue.abbreviation
        }
    }
    
    var result: WSDC.Competition.Result {
        get {
            return try! WSDC.Competition.Result(string: _result)
        }
        set {
            _result = newValue.description
        }
    }
    
    var role: WSDC.Competition.Role {
        get {
            return WSDC.Competition.Role(_role)!
        }
        set {
            _role = newValue.description
        }
    }
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["divisionName", "result", "role"]
    }
    
    convenience required init(strings: [String]) throws {
        self.init()
        
        guard let wsdcId = Int(strings[0]),
            divisionName = WSDC.DivisionName(abbreviation: strings[1]),
            points = Int(strings[2]),
            role = WSDC.Competition.Role(tinyRaw: strings[4]),
            eventId = Int(strings[5]),
            year = Int(strings[6]) else {
                
                throw NSError(domain: .SerializedParsing, code: .Competition, message: "Could not parse competition: \(strings)")
        }
        
        self._id = NSUUID().UUIDString
        self.wsdcId = wsdcId
        self.points = points
        self.divisionName = divisionName
        self.result = try WSDC.Competition.Result(string: strings[3])
        self.role = role
        self.eventId = eventId
        self.year = year + 2000
    }
}