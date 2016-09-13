//
//  UIButton.swift
//  Points
//
//  Created by Glen Hinkle on 9/6/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    func centerImage() {
        
        guard let imageSize = imageView?.bounds.size,
            let font = titleLabel?.font,
            let text = titleLabel?.text else {
                return
        }
        
        let textSize = NSString(string: text).size(attributes: [NSFontAttributeName: font])
        
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -imageSize.height, right: 0)
        imageEdgeInsets = UIEdgeInsets(top: -textSize.height, left: 0, bottom: 0, right: -textSize.width)
        let edgeOffset = abs(textSize.height - imageSize.height) / 2
        contentEdgeInsets = UIEdgeInsets(top: edgeOffset, left: 0, bottom: edgeOffset, right: 0)
    }
}
