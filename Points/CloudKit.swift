//
//  CloudKit.swift
//  Points
//
//  Created by Glen Hinkle on 7/4/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CloudKit

extension CKSubscription {
    enum SubscriptionType {
        case Competitors
        case Events
        case Competitions
        case Dumps
        
        var description: String {
            return "\(self)"
        }
    }
    
    convenience init(_ recordType: CKRecord.RecordType, predicate: NSPredicate, subscriptionID: SubscriptionType, options: CKSubscriptionOptions) {
        self.init(recordType: recordType.rawValue, predicate: predicate, subscriptionID: subscriptionID.description, options: options)
    }
}

extension CKRecord {
    
    enum RecordType: String {
        case Competitors
        case Events
        case Competitions
        case Dumps
    }
    
    convenience init(_ type: RecordType, id: NSUUID) {
        let recordID = CKRecordID(recordName: id.UUIDString)
        self.init(recordType: type.rawValue, recordID: recordID)
    }
    
    class func createDump(dump: Dump) -> CKRecord {
        let record = CKRecord(.Dumps, id: dump.id)
        
        record["id"] = dump.id.UUIDString
        record["date"] = dump.date
        record["version"] = dump.version
        record["data"] = dump.data
        
        return record
    }
    
}