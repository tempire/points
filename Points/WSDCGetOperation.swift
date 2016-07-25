//
//  WSDCGetOperation.swift
//  Points
//
//  Created by Glen Hinkle on 7/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CloudKit

protocol WSDCGetOperationDelegate: class {
    func didCompleteCompetitorIdsRetrieval(operation: WSDCGetOperation, competitorIds: [Int], completion: Void->Void)
    func didCompleteCompetitorsRetrieval(operation: WSDCGetOperation, competitors: [WSDC.Competitor])
    func didCancelOperation(operation: WSDCGetOperation, competitors: [WSDC.Competitor])
    func didPackRetrievedData(operation: WSDCGetOperation, data: NSData)
    func errorReported(operation: WSDCGetOperation, error: NSError, requeuing: Bool)
    func shouldRequeueAfterError(operation: WSDCGetOperation, error: NSError, competitorId: Int) -> Bool
}

class WSDCGetOperation: Operation, NSProgressReporting {
    let queue = NSOperationQueue()
    let progress: NSProgress
    
    //var throughputTimes = [NSTimeInterval]()
    
    weak var delegate: WSDCGetOperationDelegate?
    
    var maxConcurrentCount: Int {
        didSet {
            queue.maxConcurrentOperationCount = maxConcurrentCount
        }
    }
    
    var competitorIds = [Int]()
    var competitors: [WSDC.Competitor] = []
    var errors = [NSError]()
    
    lazy var lastOp: Operation = {
        return bo { [unowned self] op in
            
            if self.cancelled {
                self.delegate?.didCancelOperation(self, competitors: self.competitors)
                
                return op.done()
            }
            
            do {
                self.delegate?.didCompleteCompetitorsRetrieval(self, competitors: self.competitors)
                
                let data = try self.pack(self.competitors)
                try data.writeToDumps(path: "dump.data.bz2")
                
                self.delegate?.didPackRetrievedData(self, data: data)
            }
            catch let error as NSError {
                self.errors.append(error)
                self.delegate?.errorReported(self, error: error, requeuing: false)
            }
        }
    }()
    
    func pack(competitors: [WSDC.Competitor]) throws -> NSData {
        
        var date = NSDate()
        
        var serialized = (
            dancers: [String](),
            competitions: [String](),
            events: [String]()
        )
        
        // Events, duplicates removed
        
        let eventsDict = competitors.reduce([Int:Set<WSDC.Event>]()) { tmp, competitor in
            var eventsDict = tmp
            
            serialized.dancers.append(competitor.serialized)
            
            for division in competitor.divisions {
                for competition in division.competitions {
                    
                    // Competitions
                    serialized.competitions.append(competition.serialized(withId: competitor.wsdcId, andDivision: division.name))
                    
                    // Event insert
                    if eventsDict[competition.event.id] == nil {
                        eventsDict[competition.event.id] = Set<WSDC.Event>()
                    }
                    eventsDict[competition.event.id]!.insert(competition.event)
                }
            }
            
            return eventsDict
        }
        
        // Combine events, indexed on id + year
        
        serialized.events = eventsDict.values.map { events in
            let string = [
            String(events.first!.id),
            events.first!.name,
            events.first!.location,
            String(events.first!.date.month()),
            events.map { String($0.date.year() - 2000) }.joinWithSeparator(",")
            ].joinWithSeparator("^")
            
            return string
        }
        
        var strings = "__events__\n" + serialized.events.joinWithSeparator("\n")
        strings += "\n__competitions__\n" + serialized.competitions.joinWithSeparator("\n")
        strings += "\n__dancers__\n" + serialized.dancers.joinWithSeparator("\n")
        
        let data = strings.dataUsingEncoding(NSUTF8StringEncoding)
        
        print("SERIALIZATION TIME: \(NSDate().timeIntervalSinceDate(date))")
        
        date = NSDate()
        
        let compressed = try BZipCompression.compressedDataWithData(data, blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor)
        
        print("COMPRESSION TIME: \(NSDate().timeIntervalSinceDate(date))")
        
        return compressed
    }

    init(maxConcurrentCount: Int, delegate: WSDCGetOperationDelegate, progress: NSProgress) {
        self.maxConcurrentCount = maxConcurrentCount
        queue.maxConcurrentOperationCount = maxConcurrentCount
        self.progress = progress
        self.delegate = delegate
    }
    
    override func start() {
        super.start()
        
        //competitorIds = getCompetitorIds()
        competitorIds = [10915, 8836]
        // tony schubert
        //competitorIds = [7353]
        
        if competitorIds.count == 0 {
            return self.cancel()
        }
        
        delegate?.didCompleteCompetitorIdsRetrieval(self, competitorIds: competitorIds) {
            
            self.progress.totalUnitCount += self.competitorIds.count
            
            self.queue.suspended = true
            
            self.queue.addOperation(self.lastOp)
            
            let rangeMax = min(self.competitorIds.count, 20)
            
            self.queue.addOperations(
                (0..<rangeMax).map { _ in self.competitorOp(self.competitorIds.removeLast()) },
                waitUntilFinished:  false
            )
            self.queue.suspended = false
        }
    }
    
    deinit {
        print("-DEINIT \(self.dynamicType)")
    }
    
    func getCompetitorIds() -> [Int] {
        
        //let letters = "z"
        let letters = "abcdefghijklmnopqrstuvwxyxz"
        var ids: Set<Int> = []
        
        progress.totalUnitCount = Int64(letters.characters.count)
        
        let ops = letters.characters.map { String($0) }.map { letter -> Operation in
            
            return bo { [unowned self] op in
                
                if self.cancelled {
                    return op.done()
                }
                
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
                        self.errors.append(error.nsError)
                        self.delegate?.errorReported(self, error: error.nsError, requeuing: false)
                        
                        op.done()
                        
                    case .NetworkError(let error):
                        self.progress.completedUnitCount += 1
                        self.errors.append(error)
                        self.delegate?.errorReported(self, error: error, requeuing: false)
                        
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
        //let time = NSDate()
        
        let op = bo { [unowned self] op in
            
            guard let delegate = self.delegate else {
                return
            }
            
            if self.cancelled {
                return op.done()
            }
            
            WebService.load(WebService.competitor(id)) { result in
                //self.throughputTimes.append(NSDate().timeIntervalSinceDate(time))
                
                switch result {
                    
                case .Success(let competitor):
                    self.competitors.append(competitor)
                    
                case .Error(let error):
                    self.errors.append(error.nsError)
                    
                    //let requeue = delegate.shouldRequeueAfterError(self, error: error.nsError, competitorId: id)
                    //delegate.errorReported(self, error: error.nsError, requeuing: requeue)
                    delegate.errorReported(self, error: error.nsError, requeuing: false)
                
                case .NetworkError(let error):
                    self.errors.append(error)
                    
                    
                    let requeue = delegate.shouldRequeueAfterError(self, error: error, competitorId: id)
                    delegate.errorReported(self, error: error, requeuing: requeue)
                    
                    if requeue {
                        let requeuedOp = self.competitorOp(id)
                        self.lastOp.addDependency(requeuedOp)
                        self.queue.addOperation(requeuedOp)
                        self.progress.totalUnitCount += 1
                    }
                }
                
                self.progress.completedUnitCount += 1
                op.done()
                self.triggerNextCompetitor()
                self.lastOp.removeDependency(op)
            }
        }
        
        lastOp.addDependency(op)
        
        return op
    }
}