//
//  main.swift
//  points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//


/*
import Foundation
//import LzmaSDKObjc

print("Hello, World!")

let session = NSURLSession.sharedSession()

let queue = NSOperationQueue()
queue.maxConcurrentOperationCount = 10

var competitorIds = [Int]()
var competitors: [WSDC.Competitor] = []

//let letterOps = "a".characters.map { String($0) }.map { letter -> NSOperation in
let letterOps = "abcdefghijklmnopqrstuvwxyxz".characters.map { String($0) }.map { letter -> NSOperation in
    
    let op = bo { op in
        
        print("loading \(letter)")
        
        WebService.load(WebService.search(letter)) { result in
            
            switch result {
                
            case .Success(let searchResults):
                competitorIds += searchResults.competitors.map { return $0.wsdcId }
                op.done()
                
            case .Error(let error):
                print(error)
                op.done()
            }
        }
    }
    
    return op
}

queue.addOperations(letterOps, waitUntilFinished: true)
competitorIds = Array(Set(competitorIds))
var count = 0

let times = [String:NSDate]()

print("Retrieving \(competitorIds.count) competitors")

let competitorOp = { (id: Int) -> Operation in
    
    return bo { op in
        count += 1
        print("Retrieving \(count) / \(competitorIds.count)")
        
        WebService.load(WebService.competitor(id)) { result in
            
            switch result {
                
            case .Success(let competitor):
                competitors.append(competitor)
                op.done()
                
            case .Error(let error):
                print("Error for \(id): \(error)")
                op.done()
            }
        }
    }
}

queue.addOperations(competitorIds.map { competitorOp($0) }, waitUntilFinished: true)

//guard let documentsDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first,
//    unprettyJSON = try? NSJSONSerialization.dataWithJSONObject(competitors.map { $0.json }, options: []),
//    prettyJSON = try? NSJSONSerialization.dataWithJSONObject(competitors.map { $0.json }, options: [.PrettyPrinted]),
//    unprettyJSONString = String(data: prettyJSON, encoding: NSUTF8StringEncoding),
//    prettyJSONString = String(data: prettyJSON, encoding: NSUTF8StringEncoding) else {
//        exit(0)
//}
//
//do {
//    try prettyJSONString.writeToFile("\(documentsDir)/competitors-pretty.json", atomically: true, encoding: NSUTF8StringEncoding)
//    try unprettyJSONString.writeToFile("\(documentsDir)/competitors.json", atomically: true, encoding: NSUTF8StringEncoding)
//}
//catch {
//    print(error)
//}

CFRunLoopRun()
 */