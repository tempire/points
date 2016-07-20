//
//  Notifier.swift
//  Points
//
//  Created by Glen Hinkle on 7/17/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

protocol Notification: RawRepresentable { }

class Notifier {
    static var notificationCenter = NSNotificationCenter.defaultCenter()
    
    class func listenFor<T: Notification>(
        notice: T, on: NSObject, with: Selector,
        file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) {
        
        if let name = notice.rawValue as? String {
            notificationCenter.addObserver(on, selector: with, name: name, object: .None)
        }
    }
    
    class func stopListeningOn(observer: NSObjectProtocol) {
        print("*** STOPPED LISTENING on observer: \(observer)")
        notificationCenter.removeObserver(observer)
    }
    
    class func emit<T: Notification>(name: T, _ object: AnyObject? = .None,
                    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) {
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        if let name = name.rawValue as? String {
            let fileName: String = file.componentsSeparatedByString("/").last!
            print("*** EVENT EMITTED FOR \(name) \(fileName):\(line)#\(column).\(function)")
            notificationCenter.postNotificationName(name, object: object)
            return
        }
        
        assert(false, "Invalid Notification emitted: \(name). Has no rawValue as String")
    }
}