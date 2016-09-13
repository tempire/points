//
//  Spotlight.swift
//  Points
//
//  Created by Glen Hinkle on 7/20/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import CoreSpotlight

private let domainPrefix = "com.zombiedolphin.points"

enum SpotlightNotice: String, Notification {
    case IndexError
    case RemoveError
    
    static let allValues = [
        IndexError,
        RemoveError
    ]
}


class Spotlight {
    
    enum Domain: String {
        case Base = "com.zombiedolphin.points"
        case Dancer = "com.zombiedolphin.points.dancer"
    }
    
    static func createItem(_ id: String, domain: Domain, attributeSet: CSSearchableItemAttributeSet) -> CSSearchableItem {
        return CSSearchableItem(
            uniqueIdentifier: id,
            domainIdentifier: domain.rawValue,
            attributeSet: attributeSet
        )
    }
    
    static func indexItems(_ items: [CSSearchableItem], completion: ((Error?)->Void)? = .none) {
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error as? NSError {
                Notifier.emit(SpotlightNotice.IndexError, ["error": error.localizedDescription as AnyObject])
            }
            completion?(error as NSError?)
        }
    }
    
    static func removeAll(_ completion: @escaping (Error?)->Void) {
        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: completion)
    }
    
    static func removeItems(_ ids: [String], completion: ((Error?)->Void)? = .none) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids) { error in
            if let error = error as? NSError {
                Notifier.emit(SpotlightNotice.RemoveError, ["error": error.localizedDescription])
            }
            completion?(error as NSError?)
        }
    }
    
    static func replaceItem(_ item: CSSearchableItem) {
        Spotlight.removeItems([item.uniqueIdentifier]) { error in
            if error == nil {
                Spotlight.indexItems([item], completion: .none)
            }
        }
    }
}
