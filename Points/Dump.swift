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
import YSMessagePack
import RealmSwift

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
    
    convenience init(id: NSUUID, date: NSDate, version: Int, competitors: [WSDC.Competitor]) throws {
        self.init()
        
        self.id = id
        self.date = date
        self.version = version
        
        let documentsDir = NSSearchPathForDirectoriesInDomains(
            NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask,
            true).first!
        
        //let uncompressed = try NSJSONSerialization.dataWithJSONObject(self.competitors.map { $0.json }, options: [])
        
        let packed = pack(items: competitors.map { $0.json })
        
        print(try packed.itemsUnpacked())
            
        
        return;
        
        let compressed = try BZipCompression.compressedDataWithData(packed, blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor)
        
        let folderPath = "\(documentsDir)/dumps/\(NSDate().toString(format: .ISO8601))"
        try NSFileManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: .None)
        
        //uncompressed.writeToFile("\(folderPath)/competitors.json", atomically: true)
        //packed.writeToFile("\(folderPath)/competitors.messagepack", atomically: true)
        compressed.writeToFile("\(folderPath)/competitors.messagepack.bzip2", atomically: true)
        
        self.data = compressed
    }
}