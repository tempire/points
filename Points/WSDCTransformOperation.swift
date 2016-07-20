/*
//
//  WSDCTransformOperation.swift
//  Points
//
//  Created by Glen Hinkle on 7/15/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

class WSDCTransformOperation: Operation {
    let competitors: [WSDC.Competitor]
    
    init(competitors: [WSDC.Competitor]) {
        self.competitors = competitors
    }
    
    override func start() {
        super.start()
        
        var dancer_serialized = [String]()
        var competition_serialized = [String]()
        var event_serialized = [String]()
        
        let events = competitors.reduce(Set<WSDC.Event>()) { tmp, competitor in
            var set = tmp
            
            for division in competitor.divisions {
                for competition in division.competitions {
                    set.insert(competition.event)
                }
            }
            
            return set
        }
        
        for event in events {
            event_serialized.append(event.serialized)
        }
        
        for competitor in competitors {
            dancer_serialized.append(competitor.serialized)
            
            for division in competitor.divisions {
                for competition in division.competitions {
                    competition_serialized.append(competition.serialized(withId: competitor.id, andDivision: division.name))
                }
            }
        }
        
        let documentsDir = NSSearchPathForDirectoriesInDomains(
            NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask,
            true).first!
        
        let folder = "\(documentsDir)/data/\(NSDate().toString)"
        
        do {
            try NSFileManager().createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: .None)
            try dancer_serialized.joinWithSeparator("\n").writeToFile("\(folder)/dancers.txt", atomically: true, encoding: NSUTF8StringEncoding)
            try competition_serialized.joinWithSeparator("\n").writeToFile("\(folder)/competitions.txt", atomically: true, encoding: NSUTF8StringEncoding)
            try event_serialized.joinWithSeparator("\n").writeToFile("\(folder)/events.txt", atomically: true, encoding: NSUTF8StringEncoding)
        }
        catch {
            print(error)
        }
        
    }
}
*/