//
//  MGSwipeButton.swift
//  Points
//
//  Created by Glen Hinkle on 8/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import MGSwipeTableCell

extension MGSwipeButton {
    
    enum SwipeButton: Int {
        case Partner = 0
        case Competition
        case Event
        
        init?(_ int: Int?) {
            guard let int = int, value = SwipeButton(rawValue: int) else {
                return nil
            }
            
            self = value
        }
        
        var description: String {
            
            switch self {
                
            case .Partner:
                return "Partner"
                
            case .Competition:
                return "Comp"
                
            case .Event:
                return "Event"
            }
        }
        
        var icon: UIImage {
            
            switch self {
                
            case .Partner:
                return UIImage(asset: .Partner_Group)
                
            case .Competition:
                return UIImage(asset: .Partner_Group)
                
            case .Event:
                return UIImage(asset: .Partner_Group)
            }
        }
    }
    
    convenience init(_ type: SwipeButton, backgroundColor: UIColor) {
        self.init(title: type.description, icon: type.icon, backgroundColor: backgroundColor)
        setPadding(24)
        tintColor = .whiteColor()
    }
}