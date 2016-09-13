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
    static var notificationCenter = NotificationCenter.default
    
    class func listenFor<T: Notification>(
        _ notice: T, on: NSObject, with: Selector,
        file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) {
        
        if let name = notice.rawValue as? String {
            notificationCenter.addObserver(on, selector: with, name: NSNotification.Name(rawValue: name), object: .none)
        }
    }
    
    class func stopListeningOn(_ observer: NSObjectProtocol) {
        print("*** STOPPED LISTENING on observer: \(observer)")
        notificationCenter.removeObserver(observer)
    }
    
    class func emit<T: Notification>(_ name: T, _ object: Any? = .none,
                    file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) {
        
        let notificationCenter = NotificationCenter.default
        
        if let name = name.rawValue as? String {
            let fileName: String = file.components(separatedBy: "/").last!
            print("*** EVENT EMITTED FOR \(name) \(fileName):\(line)#\(column).\(function)")
            notificationCenter.post(name: Foundation.Notification.Name(rawValue: name), object: object)
            return
        }
        
        assert(false, "Invalid Notification emitted: \(name). Has no rawValue as String")
    }
}
