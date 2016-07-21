//
//  Maps.swift
//  Points
//
//  Created by Glen Hinkle on 7/20/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation


class Maps {
    
    class func canOpenAtAddress(address: String?) -> Bool {
        
        guard let address = address?.stringByReplacingOccurrencesOfString("", withString: "", options: .RegularExpressionSearch, range: nil)
            .stringByReplacingOccurrencesOfString("\n", withString: " ", options: .RegularExpressionSearch, range: nil)
            .stringByReplacingOccurrencesOfString(" ", withString: "+", options: .RegularExpressionSearch, range: nil) where !address.isEmpty else {
                return false
        }
        
        return true
    }
    
    class func openAtAddress(address: String?) -> Bool {
        
        guard let address = address?.stringByReplacingOccurrencesOfString("\n", withString: " ", options: .RegularExpressionSearch, range: nil).stringByReplacingOccurrencesOfString(" ", withString: "+", options: .RegularExpressionSearch, range: nil),
            url = NSURL(string: "http://maps.apple.com/?q=\(address)") where !address.isEmpty else {
                
                return false
        }
        
        return UIApplication.sharedApplication().openURL(url)
    }
}