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
        case dumps
        
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
    
    class func latest(_ recordType: CKRecord.RecordType) -> CKQuery {
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
                return .dumps
            }
        }
    }
    
    convenience init(_ type: RecordType, id: UUID) {
        let recordID = CKRecordID(recordName: id.uuidString)
        self.init(recordType: type.rawValue, recordID: recordID)
    }
    
    class func createDump(_ dump: Dump) -> CKRecord {
        let record = CKRecord(.Dumps, id: dump.id as UUID)
        
        record["id"] = dump.id.uuidString as CKRecordValue?
        record["date"] = dump.date as CKRecordValue?
        record["version"] = dump.version as CKRecordValue?
        record["data"] = dump.data as CKRecordValue?
        
        return record
    }
    
}
