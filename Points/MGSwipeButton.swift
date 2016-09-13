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
        case partner = 0
        case competition
        case event
        
        init?(_ int: Int?) {
            guard let int = int, let value = SwipeButton(rawValue: int) else {
                return nil
            }
            
            self = value
        }
        
        var button: MGSwipeButton {
            return MGSwipeButton(self, backgroundColor: UIColor.darkGray)
        }
        
        var description: String {
            
            switch self {
                
            case .partner:
                return "Partner"
                
            case .competition:
                return "Comp"
                
            case .event:
                return "Event"
            }
        }
        
        var icon: UIImage {
            
            switch self {
                
            case .partner:
                return UIImage(asset: .Partner_Group)
                
            case .competition:
                return UIImage(asset: .Partner_Group)
                
            case .event:
                return UIImage(asset: .Partner_Group)
            }
        }
    }
    
    convenience init(_ type: SwipeButton, backgroundColor: UIColor) {
        self.init(title: type.description, icon: type.icon, backgroundColor: backgroundColor)
        setPadding(24)
        tintColor = UIColor.white
    }
}
