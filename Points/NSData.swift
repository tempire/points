//
//  NSData.swift
//  Points
//
//  Created by Glen Hinkle on 7/16/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

let documentsDir = NSSearchPathForDirectoriesInDomains(
    FileManager.SearchPathDirectory.documentDirectory,
    FileManager.SearchPathDomainMask.userDomainMask,
    true).first!

extension Data {
    
    func writeToDumps(path: String) throws {
        
        let folder = "\(documentsDir)/dumps/\(Date().toString)"
        
        try FileManager().createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: .none)
        
        try write(to: URL(fileURLWithPath: "\(folder)/\(path)"), options: [.atomic])
    }
}
