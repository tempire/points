//
//  Media.swift
//  Points
//
//  Created by Glen Hinkle on 9/2/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import RealmSwift

class Media: Object {
    
    enum `Type`: String {
        case Youtube
        case Vimeo
        case SongName
        case AppleMusic
        case Spotify
    }
    
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var _type: String = ""
    dynamic var _url: String = ""
    
    let competition = LinkingObjects(fromType: Competition.self, property: "media")
    
    override static func ignoredProperties() -> [String] {
        return ["url", "type"]
    }
    
    var type: Type {
        get {
            return Type(rawValue: _type)!
        }
        set {
            _type = newValue.rawValue
        }
    }
    
    var url: URL? {
        get {
            return URL(string: _url)
        }
        set {
            if let newValue = newValue {
                _url = newValue.absoluteString
            }
        }
    }
}
