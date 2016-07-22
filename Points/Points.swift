//
//  Database.swift
//  Points
//
//  Created by Glen Hinkle on 7/15/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CloudKit
import BTree
import RealmSwift
import CoreSpotlight

//func ==(lhs: Points.Event, rhs: Points.Event) -> Bool { return rhs.hashValue == lhs.hashValue }

enum Points {
    
    static func addSubscriptionForNewPoints(completion: (CKSubscription?, NSError?)->Void) {
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let op = CKSubscription(.Dumps, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        let info = CKNotificationInfo()
        info.alertBody = "Dumps Subscription"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        
        publicDatabase.saveSubscription(op, completionHandler: completion)
    }
    
    static func importData(data: NSData, into realm: Realm, with progress: NSProgress) throws {
        
        let uncompressed = try BZipCompression.decompressedDataWithData(data)
        
        guard let strings = String(data: uncompressed, encoding: NSUTF8StringEncoding)?.componentsSeparatedByString("\n") else {
            throw NSError(domain: .SerializedParsing, code: .Strings, message: "Could not parse data as strings - uncompressed data length: \(data.length)")
        }
        
        let objects = try Points.objects(strings, progress: progress)
        var spotlightItems = [CSSearchableItem]()
        
        realm.beginWrite()
        
        objects.forEach {
            realm.add($0, update: true)
            
            if let dancer = $0 as? Dancer {
                spotlightItems.append(Spotlight.createItem("\(dancer.id)", domain: .Dancer, attributeSet: dancer.searchableAttributeSet))
            }
        }
        
        Spotlight.indexItems(spotlightItems) { _ in }
        
        try realm.commitWrite()
    }
    
    static func objects(strings: [String], progress: NSProgress) throws -> [Object] {
        
        var objects = [Object]()
        var compsByDancerId = [Int:[Competition]]()
        var eventYearsByIdAndYear = [String:EventYear]()
        
        progress.totalUnitCount = Int64(strings.count)
        
        var identifier = ""
        
        for string in strings where string.characters.count > 2 {
            
            if string[string.startIndex..<string.startIndex.advancedBy(2)] == "__" {
                identifier = string[string.startIndex.advancedBy(2)..<string.endIndex.advancedBy(-2)]
                continue
            }

            switch identifier {
            case "dancers":
                let dancer = try Dancer(string)
                
                if let comps = compsByDancerId[dancer.id] {
                    for comp in comps {
                        dancer.competitions.append(comp)
                    }
                }
                
                dancer.rank = dancer.calculateRank()
                
                objects.append(dancer)
                
            case "competitions":
                let competition = try Competition(string)
                competition.eventYear = eventYearsByIdAndYear[String(competition.eventId) + String(competition.year)]
                
                if compsByDancerId[competition.wsdcId] == nil {
                    compsByDancerId[competition.wsdcId] = []
                }
                compsByDancerId[competition.wsdcId]!.append(competition)
                
                objects.append(competition)
                
            case "events":
                let eventYears = try EventYear.createEvents(string.componentsSeparatedByString("^"))
                
                eventYears.forEach {
                    objects.append($0)
                    let key = String($0.event.id) + String($0.year)
                    eventYearsByIdAndYear[key] = $0
                }
                
            default:
                throw NSError(domain: .SerializedParsing, code: .SectionTitle, message: "Could not parse section title in strings data: \(identifier)")
            }
            
            progress.completedUnitCount += 1
        }
        
        return objects
    }
}