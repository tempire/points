//
//  Dancer.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import RealmSwift
import CoreSpotlight

class Dancer: Object, StringImport {
    dynamic var id: Int = 0
    dynamic var fname: String = ""
    dynamic var lname: String = ""
    dynamic var name: String = ""
    dynamic fileprivate var _maxRank: String = ""
    dynamic fileprivate var _minRank: String = ""
    
    let competitions = List<Competition>()
    
    typealias Rank = (min: WSDC.DivisionName, max: WSDC.DivisionName)
    
    var rank: (min: WSDC.DivisionName, max: WSDC.DivisionName) {
        get {
            return calculateRank()
            
            /*
            if !_minRank.isEmpty && !_maxRank.isEmpty {
                return (
                    WSDC.DivisionName(abbreviation: _minRank)!,
                    WSDC.DivisionName(abbreviation: _maxRank)!
                )
            }
            
            self.rank = calculateRank()
            
            return self.rank
            */
        }
        set {
            _minRank = newValue.min.abbreviation
            _maxRank = newValue.max.abbreviation
        }
    }
    
    var divisionNamesInDisplayOrder: [WSDC.DivisionName] {
        let comps = competitions.reduce(Set<WSDC.DivisionName>()) { tmp, comp in
            var set = tmp
            set.insert(comp.divisionName)
            return set
        }
        
        return comps.sorted { left, right in
            return left < right
            //return WSDC.DivisionName.displayOrder[left] < WSDC.DivisionName.displayOrder[right]
        }
    }
    
    func points(forDivision divisionName: WSDC.DivisionName) -> [WSDC.Competition.Role:Int] {
        
        return competitions
            .filter { $0.divisionName == divisionName }
            .reduce([WSDC.Competition.Role.Lead: 0, WSDC.Competition.Role.Follow: 0]) { tmp, comp in
                var dict = tmp
                
                dict[comp.role]! += comp.points
                
                return dict
        }
    }
    
    func calculateRank() -> Rank {
        let rankOrder = WSDC.DivisionName.rankOrder
        
        var points: [WSDC.DivisionName:Int] = [:]
        
        let min = WSDC.DivisionName.NOV
        var max = WSDC.DivisionName.NOV
        
        for comp in competitions {
            
            if points[comp.divisionName] == .none {
                points[comp.divisionName] = 0
            }
            
            points[comp.divisionName]! += comp.points
            
            if let nextRank = comp.divisionName.nextRank,
                let divisionPoints = points[comp.divisionName],
                let nextRankPoints = comp.divisionName.pointsForNextRank,
                let nextRankOrder = rankOrder[nextRank],
                let maxRankOrder = rankOrder[max],
                divisionPoints > nextRankPoints,
                nextRankOrder > maxRankOrder {
                
                max = nextRank
            }
            
            if let divisionRankOrder = rankOrder[comp.divisionName],
                let maxRankOrder = rankOrder[max],
                divisionRankOrder > maxRankOrder {
                
                max = comp.divisionName
            }
        }
        
        return (min: min, max: max)
    }

    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["rank"]
    }
    
    convenience required init(strings: [String]) throws {
        self.init()
        
        guard let id = Int(strings[0]) else {
                throw NSError(domain: .serializedParsing, code: .dancer, message: "Could not parse dancer: \(strings)")
        }
        
        self.id = id
        fname = strings[1]
        lname = strings[2]
        
        name = fname + " " + lname
    }
    
    var searchableAttributeSet: CSSearchableItemAttributeSet {
        let attr = CSSearchableItemAttributeSet(itemContentType: Spotlight.Domain.Dancer.rawValue)
        attr.title = name
        attr.keywords = []
        attr.keywords?.append("\(id)")
        
        attr.contentDescription = rank.max.description + "\n\(id)"
        
        return attr
    }
    
    
    
    

}
