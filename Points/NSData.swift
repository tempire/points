//
//  NSData.swift
//  Points
//
//  Created by Glen Hinkle on 7/16/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

let documentsDir = NSSearchPathForDirectoriesInDomains(
    NSSearchPathDirectory.DocumentDirectory,
    NSSearchPathDomainMask.UserDomainMask,
    true).first!

extension NSData {
    
    func writeToDumps(path path: String) throws {
        
        let folder = "\(documentsDir)/dumps/\(NSDate().toString)"
        
        try NSFileManager().createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: .None)
        
        writeToFile("\(folder)/\(path)", atomically: true)
    }
}