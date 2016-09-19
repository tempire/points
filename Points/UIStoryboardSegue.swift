//
//  UIStoryboardSegue.swift
//  Points
//
//  Created by Glen Hinkle on 9/9/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboardSegue {
    
    enum SegueIdentifier: String {
        case dancer
        case partner
        case firstPartner
        case secondPartner
        case division
        case importer
        case event
        
        init?(_ rawValue: String?) {
            guard let rawValue = rawValue, let value = SegueIdentifier(rawValue: rawValue) else {
                return nil
            }
            
            self = value
        }
    }
    
    var identifierType: SegueIdentifier? {
        return SegueIdentifier(identifier)
    }
}
