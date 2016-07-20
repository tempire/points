//
//  DumpVC.swift
//  Points
//
//  Created by Glen Hinkle on 7/15/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

class DumpVC: UIViewController {
    var dump: Dump?
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var competitorsCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let dump = dump else {
            return
        }
        
        dateLabel.text = dump.date.toString
        versionLabel.text = "\(dump.version)"
    }
    
}