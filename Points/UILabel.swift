//
//  UILabel.swift
//  Points
//
//  Created by Glen Hinkle on 7/23/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

class InsetLabel: UILabel {
    
    var insets: UIEdgeInsets {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        let size = super.intrinsicContentSize()
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
    
    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.insets = UIEdgeInsetsZero
        super.init(coder: aDecoder)
    }
    
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}