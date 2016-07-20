//
//  DancerVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/19/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import CoreSpotlight

class DancerVC: UIViewController {
    var dancer: Dancer!
    
    @IBOutlet weak var label: UILabel! {
        didSet {
            label.text = dancer?.name
        }
    }
}


// Open from spotlight

extension DancerVC {
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        guard activity.activityType == CSSearchableItemActionType else {
            return
        }
        
        let realm = try! Realm()
        
        if let value = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            dancerId = Int(value),
            dancer = realm.objects(Dancer).filter("id = %d", dancerId).first {
            self.dancer = dancer
            self.label.text = dancer.name
        }
    }
}