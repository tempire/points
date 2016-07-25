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
    
    static func createItem(id: String, domain: Domain, attributeSet: CSSearchableItemAttributeSet) -> CSSearchableItem {
        return CSSearchableItem(
            uniqueIdentifier: id,
            domainIdentifier: domain.rawValue,
            attributeSet: attributeSet
        )
    }
    
    static func indexItems(items: [CSSearchableItem], completion: ((NSError?)->Void)? = .None) {
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(items) { error in
            if let error = error {
                Notifier.emit(SpotlightNotice.IndexError, ["error": error.localizedDescription])
            }
            completion?(error)
        }
    }
    
    static func removeAll(completion: (NSError?->Void)) {
        CSSearchableIndex.defaultSearchableIndex().deleteAllSearchableItemsWithCompletionHandler(completion)
    }
    
    static func removeItems(ids: [String], completion: ((NSError?)->Void)? = .None) {
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers(ids) { error in
            if let error = error {
                Notifier.emit(SpotlightNotice.RemoveError, ["error": error.localizedDescription])
            }
            completion?(error)
        }
    }
    
    static func replaceItem(item: CSSearchableItem) {
        Spotlight.removeItems([item.uniqueIdentifier]) { error in
            if error == .None {
                Spotlight.indexItems([item], completion: .None)
            }
        }
    }
}