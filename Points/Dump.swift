//
//  Dumps.swift
//  Points
//
//  Created by Glen Hinkle on 7/15/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

//
//  Event.swift
//  Pinpoint
//
//  Created by Glen Hinkle on 7/1/16.
//  Copyright © 2016 VIvint Solar Inc. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit

protocol PrimaryKeyIdObject: class {
    var id: UUID { get set }
}

class Dump: Object, PrimaryKeyIdObject {
    dynamic var _id: String = ""
    dynamic var date: Date = Date()
    dynamic var version: Int = 0
    dynamic var data: Data = Data()
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["id"]
    }
    
    var id: UUID {
        get {
            return UUID(uuidString: _id)!
        }
        set {
            _id = newValue.uuidString
        }
    }
    
    convenience init(ckRecord record: CKRecord) throws {
        self.init()
        
        guard let _id = record["id"] as? String,
            let id = UUID(uuidString: _id),
            let date = record["date"] as? Date,
            let version = record["version"] as? Int,
            let data = record["data"] as? Data else {
                return
        }
        
        self.id = id
        self.date = date
        self.version = version
        self.data = data
    }
    
    convenience init(id: UUID, date: Date, version: Int, data: Data) throws {
        self.init()
        
        self.id = id
        self.date = date
        self.version = version
        self.data = data
    }
}
