//
//  main.swift
//  cli
//
//  Created by Glen Hinkle on 7/11/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CloudKit

print("Hello, World!")

let session = NSURLSession.sharedSession()

let queue = NSOperationQueue()
queue.maxConcurrentOperationCount = 10

var compressed: NSData?
var competitorCount = 0

var competitorIds = [Int]()
var competitors: [WSDC.Competitor] = []

//let letterOps = "a".characters.map { String($0) }.map { letter -> NSOperation in
let letterOps = "abcdefghijklmnopqrstuvwxyxz".characters.map { String($0) }.map { letter -> NSOperation in
//let letterOps = "z".characters.map { String($0) }.map { letter -> NSOperation in
    
    let op = bo { op in
        
        print("loading \(letter)")
        
        WebService.load(WebService.search(letter)) { result in
            
            switch result {
                
            case .Success(let searchResults):
                competitorIds += searchResults.competitors.map { return $0.wsdcId }
                op.done()
                
            case .Error(let error):
                print(error)
                exit(0)
                op.done()
            }
        }
    }
    
    return op
}

let writeCloudKitOp = bo { op in
    //let container = CKContainer.defaultContainer()
    let container = CKContainer(identifier: "iCloud.com.zombiedolphin.Points")

    let publicDatabase = container.publicCloudDatabase
    
    /*
     container.requestApplicationPermission(.UserDiscoverability) { status, error in
     container.discoverAllContactUserInfosWithCompletionHandler { userInfo, error in
     
     }
     }
     
     let op = CKSubscription(.Dumps, predicate: NSPredicate.all, subscriptionID: .Dumps, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
     
     op.notificationInfo = CKNotificationInfo()
     op.notificationInfo?.alertBody = "Competitor Thing"
     op.notificationInfo?.shouldBadge = true
     op.notificationInfo?.shouldSendContentAvailable = true
     
     publicDatabase.saveSubscription(op) { subscription, error in
     
     }
     */
    
    let date = NSDate()
    
    let record = CKRecord(.Competitors, name: date.toString)
    record["dump"] = compressed
    record["timestamp"] = date
    record["count"] = competitorCount
    
    publicDatabase.saveRecord(record) { record, error in
        print(record)
        print(error)
        
        exit(0)
    }
    /*
     container.fetchUserRecordIDWithCompletionHandler { recordID, error in
     publicDatabase.fetchRecordWithID(recordID!) { record, error in
     
     }
     }
     
     publicDatabase.deleteRecordWithID(CKRecordID(recordName: "_facdec1a146ff3ff4a702897f1371f4f")) { recordID, error in
     
     }
     */
}

compressed = NSData(contentsOfFile: "competitors.messagepack.bzip2")

queue.addOperation(writeCloudKitOp)

CFRunLoopRun()

exit(0)

queue.addOperations(letterOps, waitUntilFinished: true)
competitorIds = Array(Set(competitorIds))
var count = 0

let times = [String:NSDate]()

print("Retrieving \(competitorIds.count) competitors")

let writeFileOp = bo { op in
    guard let documentsDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first,
        unprettyJSON = try? NSJSONSerialization.dataWithJSONObject(competitors.map { $0.json }, options: []),
        prettyJSON = try? NSJSONSerialization.dataWithJSONObject(competitors.map { $0.json }, options: [.PrettyPrinted]),
        unprettyJSONString = String(data: prettyJSON, encoding: NSUTF8StringEncoding),
        prettyJSONString = String(data: prettyJSON, encoding: NSUTF8StringEncoding) else {
            exit(0)
    }
    
    do {
        let json = try NSJSONSerialization.JSONObjectWithData(unprettyJSON, options: []) as! [JSONObject]
        count = json.count
        let packed = pack(items: json.map {$0})
        compressed = try BZipCompression.compressedDataWithData(packed, blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor)
        packed.writeToFile("competitors.messagepack", atomically: true)
        compressed?.writeToFile("competitors.messagepack.bzip2", atomically: true)
        //try prettyJSONString.writeToFile("\(documentsDir)/acompetitors-pretty.json", atomically: true, encoding: NSUTF8StringEncoding)
        //try unprettyJSONString.writeToFile("\(documentsDir)/acompetitors.json", atomically: true, encoding: NSUTF8StringEncoding)
        try prettyJSONString.writeToFile("competitors-pretty.json", atomically: true, encoding: NSUTF8StringEncoding)
        try unprettyJSONString.writeToFile("competitors.json", atomically: true, encoding: NSUTF8StringEncoding)
    }
    catch {
        exit(0)
        print(error)
    }
}

let competitorOp = { (id: Int) -> Operation in
    
    let op = bo { op in
        count += 1
        print("Retrieving \(count) / \(competitorIds.count)")
        
        WebService.load(WebService.competitor(id)) { result in
            
            switch result {
                
            case .Success(let competitor):
                competitors.append(competitor)
                op.done()
                
            case .Error(let error):
                exit(0)
                print("Error for \(id): \(error)")
                op.done()
            }
        }
    }
    
    writeFileOp.addDependency(op)
    
    return op
}

queue.suspended = true

writeCloudKitOp.addDependency(writeFileOp)

queue.addOperation(writeFileOp)
queue.addOperation(writeCloudKitOp)

queue.addOperations(competitorIds.map { competitorOp($0) }, waitUntilFinished: false)

queue.suspended = false

CFRunLoopRun()