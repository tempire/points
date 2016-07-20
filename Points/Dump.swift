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
    var id: NSUUID { get set }
}

class Dump: Object, PrimaryKeyIdObject {
    dynamic var _id: String = ""
    dynamic var date: NSDate = NSDate()
    dynamic var version: Int = 0
    dynamic var data: NSData = NSData()
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["id"]
    }
    
    var id: NSUUID {
        get {
            return NSUUID(UUIDString: _id)!
        }
        set {
            _id = newValue.UUIDString
        }
    }
    
    convenience init(ckRecord record: CKRecord) throws {
        self.init()
        
        guard let _id = record["id"] as? String,
            id = NSUUID(UUIDString: _id),
            date = record["date"] as? NSDate,
            version = record["version"] as? Int,
            data = record["data"] as? NSData else {
                return
        }
        
        self.id = id
        self.date = date
        self.version = version
        self.data = data
    }
    
    convenience init(id: NSUUID, date: NSDate, version: Int, data: NSData) throws {
        self.init()
        
        self.id = id
        self.date = date
        self.version = version
        self.data = data
    }
}