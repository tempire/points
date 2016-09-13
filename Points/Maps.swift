//
//  Maps.swift
//  Points
//
//  Created by Glen Hinkle on 7/20/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation


class Maps {
    
    class func canOpenAtAddress(_ address: String?) -> Bool {
        
        guard let address = address?.replacingOccurrences(of: "", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "\n", with: " ", options: .regularExpression, range: nil)
            .replacingOccurrences(of: " ", with: "+", options: .regularExpression, range: nil) , !address.isEmpty else {
                return false
        }
        
        return true
    }
    
    class func openAtAddress(_ address: String?) -> Bool {
        
        guard let address = address?.replacingOccurrences(of: "\n", with: " ", options: .regularExpression, range: nil).replacingOccurrences(of: " ", with: "+", options: .regularExpression, range: nil),
            let url = URL(string: "http://maps.apple.com/?q=\(address)") , !address.isEmpty else {
                
                return false
        }
        
        return UIApplication.shared.openURL(url)
    }
}
