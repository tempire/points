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
        case Dumps
        
        var description: String {
            return "\(self)"
        }
    }
    
    convenience init(_ recordType: CKRecord.RecordType, predicate: NSPredicate, subscriptionID: SubscriptionType, options: CKSubscriptionOptions) {
        self.init(recordType: recordType.rawValue, predicate: predicate, subscriptionID: subscriptionID.description, options: options)
    }
    
    convenience init(_ recordType: CKRecord.RecordType, options: CKSubscriptionOptions) {
        self.init(recordType: recordType.rawValue, predicate: NSPredicate.all, subscriptionID: recordType.subscriptionForAll.description, options: options)
    }
}

extension CKQuery {
    
    class func latest(recordType: CKRecord.RecordType) -> CKQuery {
        let query = CKQuery(recordType: recordType.rawValue, predicate: NSPredicate.all)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return query
    }
}

extension CKRecord {
    
    enum RecordType: String {
        case Dumps
        
        var subscriptionForAll: CKSubscription.SubscriptionType {
            switch self {
            case .Dumps:
                return .Dumps
            }
        }
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