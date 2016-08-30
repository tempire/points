//
//  UIScrollView.swift
//  Points
//
//  Created by Glen Hinkle on 8/29/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
    
    var scrolledAboveContentView: Bool {
        return contentOffset.y <= 0
    }
    
    var atBottomOfContentView: Bool {
        return contentOffset.y + 1 >= contentSize.height - frame.size.height
    }
}