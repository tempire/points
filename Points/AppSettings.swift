//
//  AppSettings.swift
//  Points
//
//  Created by Glen Hinkle on 9/17/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

enum AppSettings {

    static var leadOrFollowFirst: WSDC.Competition.Role {
        guard let value = UserDefaults.standard.string(forKey: "lead_or_follow_first"),
            let role = WSDC.Competition.Role(value) else {
                return .Lead
        }
        
        return role
    }
    
    static func order(for role: WSDC.Competition.Role) -> Int {
        return role == leadOrFollowFirst ? 0 : 1
    }
}
