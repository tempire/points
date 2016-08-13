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
        return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty ? .None : self
    }
    
    init?(_ int: Int?) {
        guard let int = int else {
            return nil
        }
        
        self = String(int)
    }
    
    func height(width width: CGFloat, font: UIFont) -> CGFloat {
        
        return self.boundingRectWithSize(
            CGSize(width: width, height: CGFloat.max),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: font],
            context: .None
            ).height
    }
}