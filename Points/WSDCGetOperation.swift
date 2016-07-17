//
//  WSDCGetOperation.swift
//  Points
//
//  Created by Glen Hinkle on 7/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CloudKit
import YSMessagePack

protocol WSDCGetOperationDelegate: class {
    func didCompleteCompetitorIdsRetrieval(operation: WSDCGetOperation, competitorIds: [Int])
    func didCompleteCompetitorsRetrieval(operation: WSDCGetOperation, competitors: [WSDC.Competitor])
    //func didCompleteCompetitorsWrite(operation: WSDCGetOperation, folderPath: String, compressed: NSData)
}

class WSDCGetOperation: Operation, NSProgressReporting {
    let queue = NSOperationQueue()
    let progress: NSProgress
    
    var throughputTimes = [NSTimeInterval]()
    
    weak var delegate: WSDCGetOperationDelegate?
    
    var maxConcurrentCount: Int {
        didSet {
            queue.maxConcurrentOperationCount = maxConcurrentCount
        }
    }
    
    var competitorIds = [Int]()
    var competitors: [WSDC.Competitor] = []
    
    lazy var lastOp: Operation = {
        return bo { [unowned self] op in
            do {
                self.delegate?.didCompleteCompetitorsRetrieval(self, competitors: self.competitors)
                
                let uncompressed = try NSJSONSerialization.dataWithJSONObject(self.competitors.map { $0.json }, options: [])
                /*
                let packed = pack(items: self.competitors.map { $0.json })
                let compressed = try BZipCompression.compressedDataWithData(packed, blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor)
                 */
                
                let documentsDir = NSSearchPathForDirectoriesInDomains(
                    NSSearchPathDirectory.DocumentDirectory,
                    NSSearchPathDomainMask.UserDomainMask,
                    true).first!
                
                let folderPath = "\(documentsDir)/dumps/\(NSDate().toString)"
                try NSFileManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: .None)
                
                uncompressed.writeToFile("\(folderPath)/competitors.json", atomically: true)
                
                /*
                packed.writeToFile("\(folderPath)/competitors.messagepack", atomically: true)
                compressed.writeToFile("\(folderPath)/competitors.messagepack.bzip2", atomically: true)
                */
                
                //self.delegate?.didCompleteCompetitorsWrite(self, folderPath: folderPath, compressed: compressed)
            }
            catch {
                print(error)
            }
        }
    }()
    
    init(maxConcurrentCount: Int, delegate: WSDCGetOperationDelegate, progress: NSProgress) {
        self.maxConcurrentCount = maxConcurrentCount
        queue.maxConcurrentOperationCount = maxConcurrentCount
        self.progress = progress
        self.delegate = delegate
    }
    
    override func start() {
        super.start()
        
        competitorIds = getCompetitorIds()
        delegate?.didCompleteCompetitorIdsRetrieval(self, competitorIds: competitorIds)
        
        progress.totalUnitCount += competitorIds.count
        
        
        queue.suspended = true
        
        queue.addOperation(lastOp)
        
        queue.addOperations(
            (0..<20).map { _ in competitorOp(competitorIds.removeLast()) },
            waitUntilFinished:  false
        )
        queue.suspended = false
    }
    
    deinit {
        print("-DEINIT \(self.dynamicType)")
    }
    
    func getCompetitorIds() -> [Int] {
        
        let letters = "z"
        //let letters = "abcdefghijklmnopqrstuvwxyxz"
        var ids: Set<Int> = []
        
        //let letterProgress = NSProgress(totalUnitCount: Int64(letters.characters.count))
        //
        //progress?.addChild(letterProgress, withPendingUnitCount: 1)
        
        let ops = letters.characters.map { String($0) }.map { letter -> Operation in
            
            return bo { [unowned self] op in
                
                WebService.load(WebService.search(letter)) { result in
                    
                    switch result {
                        
                    case .Success(let searchResults):
                        
                        for competitor in searchResults.competitors {
                            print("letter \(letter) inserted")
                            ids.insert(competitor.wsdcId)
                        }
                        
                        self.progress.completedUnitCount += 1
                        
                        op.done()
                        
                    case .Error(let error):
                        self.progress.completedUnitCount += 1
                        print(error)
                        
                        op.done()
                    }
                }
            }
        }
        
        queue.addOperations(ops, waitUntilFinished: true)
        
        return Array(ids)
    }
    
    func triggerNextCompetitor() {
        let count = queue.maxConcurrentOperationCount - queue.operationCount
        if count <= 0 || competitorIds.count <= 0 {
            return
        }
        
        let ops = (0..<count).map { _ in
            competitorOp(competitorIds.removeLast())
        }
        
        /*
        // Calculate throughput
        if throughputTimes.count > 10 {
            let average = Double(String(format: "%.1f", throughputTimes.reduce(0.0, combine: +) / Double(throughputTimes.count)))!
            let secondsRemaining = Double(competitorIds.count + competitors.count) / Double(queue.maxConcurrentOperationCount) * average
            //13000/10*.4/60
            //print(throughput)
            progress.setUserInfoObject(secondsRemaining, forKey: NSProgressThroughputKey)
            throughputTimes = [] // Array(throughputTimes[0..<50])
            print(throughputTimes.count)
        }
        */
        
        queue.addOperations(ops, waitUntilFinished: false)
    }
    
    func competitorOp(id: Int) -> Operation {
        let time = NSDate()
        
        let op = bo { [unowned self] op in
            
            print(self.cancelled)
            print(self.state)
            if self.cancelled {
                return op.done()
            }
            
            WebService.load(WebService.competitor(id)) { result in
                self.throughputTimes.append(NSDate().timeIntervalSinceDate(time))
                
                switch result {
                    
                case .Success(let competitor):
                    print("competitor \(id) \(competitor.lastName) retrieved")
                    self.competitors.append(competitor)
                    self.progress.completedUnitCount += 1
                    op.done()
                    self.triggerNextCompetitor()
                    self.lastOp.removeDependency(op)
                    
                case .Error(let error):
                    self.progress.completedUnitCount += 1
                    op.done()
                    self.triggerNextCompetitor()
                    self.lastOp.removeDependency(op)
                }
            }
        }
        
        lastOp.addDependency(op)
        
        return op
    }
}

/*
 let writeCloudKitOp = bo { op in
 //let container = CKContainer.defaultContainer()
 let container = CKContainer(identifier: "iCloud.com.zombiedolphin.Points")
 
 let publicDatabase = container.publicCloudDatabase
 
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
 
 container.fetchUserRecordIDWithCompletionHandler { recordID, error in
 publicDatabase.fetchRecordWithID(recordID!) { record, error in
 
 }
 }
 
 publicDatabase.deleteRecordWithID(CKRecordID(recordName: "_facdec1a146ff3ff4a702897f1371f4f")) { recordID, error in
 
 }
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
 */