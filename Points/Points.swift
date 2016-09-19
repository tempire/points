//
//  Database.swift
//  Points
//
//  Created by Glen Hinkle on 7/15/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CloudKit
import RealmSwift
import CoreSpotlight

enum Points {
    
    static func addSubscriptionForNewPoints(_ completion: @escaping (CKSubscription?, NSError?)->Void) {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        let op = CKSubscription(.Dumps, options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        let info = CKNotificationInfo()
        info.alertBody = "Dumps Subscription"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true

        publicDatabase.save(op, completionHandler: { subscription, error in
            completion(subscription, error as? NSError)
        })
    }
    
    static func importData(_ data: Data, into realm: Realm, with progress: Progress) throws {
        
        let uncompressed = try BZipCompression.decompressedData(with: data)
        
        guard let strings = String(data: uncompressed, encoding: String.Encoding.utf8)?.components(separatedBy: "\n") else {
            throw NSError(domain: .serializedParsing, code: .strings, message: "Could not parse data as strings - uncompressed data length: \(data.count)")
        }
        
        let objects = try Points.objects(strings, progress: progress)
        var spotlightItems = [CSSearchableItem]()
        
        realm.beginWrite()
        
        objects.forEach {
            realm.add($0, update: true)
            
            // Add to spotlight
            if let dancer = $0 as? Dancer {
                spotlightItems.append(Spotlight.createItem("\(dancer.id)", domain: .Dancer, attributeSet: dancer.searchableAttributeSet))
            }
        }
        
        Spotlight.removeAll { error in
            Spotlight.indexItems(spotlightItems)
        }
        
        try realm.commitWrite()
    }
    
    struct PartnerComp {
        var follow: Competition?
        var lead: Competition?
    }
    
    static func objects(_ strings: [String], progress: Progress) throws -> [Object] {
        
        var objects = [Object]()
        var compsByDancerId = [Int:[Competition]]()
        var eventYearsByIdAndYear = [String:EventYear]()
        
        var partnerComps = [String:PartnerComp]()
        
        progress.totalUnitCount = Int64(strings.count)
        
        var identifier = ""
        
        for string in strings where string.characters.count > 2 {

            
            if string[string.startIndex..<string.index(string.startIndex, offsetBy: 2)] == "__" {
                identifier = string[string.index(string.startIndex, offsetBy: 2)..<string.index(string.endIndex, offsetBy: -2)]
                progress.completedUnitCount += 1
                continue
            }

            switch identifier {
                
            case "events":
                let eventYears = try EventYear.createEvents(string.components(separatedBy: "^"))
                
                eventYears.sorted {
                    $0.year > $1.year
                    }
                    .forEach {
                        $0.event.yearsString = eventYears.map { "\($0.year)" }.joined(separator: ", ")
                        objects.append($0)
                        let key = [String($0.event.id), String($0.year)].joined(separator: "^")
                        eventYearsByIdAndYear[key] = $0
                }
                
                print(eventYears.first?.event.yearsString)
                progress.completedUnitCount += 1
                
            case "competitions":
                
                let competition = try Competition(string)
                
                let key = [String(competition.eventId), String(competition.year)].joined(separator: "^")
                competition.eventYear = eventYearsByIdAndYear[key]
                competition.month = competition.eventYear.month
                
                if compsByDancerId[competition.wsdcId] == nil {
                    compsByDancerId[competition.wsdcId] = []
                }
                compsByDancerId[competition.wsdcId]!.append(competition)
                
                
                // Assign partner if has placement
                
                if case .placement(let placement) = competition.result {
                    
                    let key = [
                        String(placement),
                        String(competition.eventId),
                        competition.divisionName.abbreviation,
                        String(competition.year)
                        ].joined(separator: "^")
                    
                    if partnerComps[key] == nil {
                        partnerComps[key] = PartnerComp(follow: .none, lead: .none)
                    }
                    
                    switch competition.role {
                        
                    case .Lead:
                        partnerComps[key]?.lead = competition
                        
                    case .Follow:
                        partnerComps[key]?.follow = competition
                    }
                    
                    // Increment total unit count for competition placement loop below
                }
                
                progress.totalUnitCount += 1
                progress.completedUnitCount += 1
                
                objects.append(competition)
                
            case "dancers":
                let dancer = try Dancer(string)
                
                if let comps = compsByDancerId[dancer.id] {
                    for comp in comps {
                        dancer.competitions.append(comp)
                    }
                }
                
                dancer.rank = dancer.calculateRank()
                
                objects.append(dancer)
            
                progress.completedUnitCount += 1
                
            default:
                throw NSError(domain: .serializedParsing, code: .sectionTitle, message: "Could not parse section title in strings data: \(identifier)")
            }
        }
        
        for case let competition as Competition in objects {
            if case .placement(let placement) = competition.result {
                
                let key = [
                    String(placement),
                    String(competition.eventId),
                    competition.divisionName.abbreviation,
                    String(competition.year)
                    ].joined(separator: "^")
                
                switch competition.role {
                    
                case .Lead:
                    competition.partnerCompetition = partnerComps[key]?.follow
                    
                case .Follow:
                    competition.partnerCompetition = partnerComps[key]?.lead
                }
            }
            
            progress.completedUnitCount += 1
        }
        
        return objects
    }
}
