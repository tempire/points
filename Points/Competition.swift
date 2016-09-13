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
        try self.init(strings: string.components(separatedBy: "^"))
    }
}

class Competition: Object, StringImport {
    dynamic var _id: String = ""
    dynamic var wsdcId: Int = 0
    dynamic var points: Int = 0
    dynamic fileprivate var _divisionName: String = ""
    dynamic fileprivate var _result: String = ""
    dynamic fileprivate var _role: String = ""
    dynamic var eventId: Int = 0
    dynamic var year: Int = 0 // denormalized for sorting, realm does not support sorting on child relationships
    dynamic var month: Int = 0 // denormalized for sorting
    dynamic var eventYear: EventYear!
    dynamic var divisionNameDisplayOrder: Int = 0
    
    dynamic var partnerCompetition: Competition?
    
    let media = List<Media>()
    let dancer = LinkingObjects(fromType: Dancer.self, property: "competitions")
    
    var id: UUID {
        get {
            return UUID(uuidString: _id)!
        }
        set {
            _id = newValue.uuidString
        }
    }
    
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
            _result = newValue.tinyRaw
        }
    }
    
    var role: WSDC.Competition.Role {
        get {
            return WSDC.Competition.Role(tinyRaw: _role)!
        }
        set {
            _role = newValue.tinyRaw
        }
    }
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["id", "divisionName", "result", "role"]
    }
    
    convenience required init(strings: [String]) throws {
        self.init()
        
        guard let wsdcId = Int(strings[0]),
            let divisionName = WSDC.DivisionName(abbreviation: strings[1]),
            let points = Int(strings[2]),
            let role = WSDC.Competition.Role(tinyRaw: strings[4]),
            let eventId = Int(strings[5]),
            let year = Int(strings[6]) else {
                
                throw NSError(domain: .serializedParsing, code: .competition, message: "Could not parse competition: \(strings)")
        }
        
        self._id = UUID().uuidString
        self.wsdcId = wsdcId
        self.points = points
        self.divisionName = divisionName
        self.result = try WSDC.Competition.Result(string: strings[3])
        self.role = role
        self.eventId = eventId
        self.year = year + 2000
        self.divisionNameDisplayOrder = divisionName.displayOrder
    }
}
