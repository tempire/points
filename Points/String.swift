//
//  String.swift
//  Points
//
//  Created by Glen Hinkle on 7/18/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

extension String {
    
    var trim: String? {
        return trimmingCharacters(in: CharacterSet.whitespaces).isEmpty ? .none : self
    }
    
    init?(_ int: Int?) {
        guard let int = int else {
            return nil
        }
        
        self = String(int)
    }
    
    func height(width: CGFloat, font: UIFont) -> CGFloat {
        
        return self.boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: font],
            context: .none
            ).height
    }
}
