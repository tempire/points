//
//  DancerVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/19/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

class DancerVC: UIViewController {
    var dancer: Dancer!
    
    @IBOutlet weak var label: UILabel! {
        didSet {
            label.text = dancer?.name
        }
    }
}
