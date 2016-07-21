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
    dynamic private var _maxRank: String = ""
    dynamic private var _minRank: String = ""
    
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
        
        return comps.sort { left, right in
            return WSDC.DivisionName.displayOrder[left] < WSDC.DivisionName.displayOrder[right]
        }
    }
    
    func calculateRank() -> Rank {
        let rankOrder = WSDC.DivisionName.rankOrder
        
        var points: [WSDC.DivisionName:Int] = [:]
        
        var min = WSDC.DivisionName.NOV
        var max = WSDC.DivisionName.NOV
        
        for comp in competitions {
            
            if points[comp.divisionName] == .None {
                points[comp.divisionName] = 0
            }
            
            points[comp.divisionName]! += comp.points
            
            if let nextRank = comp.divisionName.nextRank
                where points[comp.divisionName] > comp.divisionName.pointsForNextRank
                    && rankOrder[nextRank] > rankOrder[max] {
                max = nextRank
            }
            
            if rankOrder[comp.divisionName] > rankOrder[max] {
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
                throw NSError(domain: .SerializedParsing, code: .Dancer, message: "Could not parse dancer: \(strings)")
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