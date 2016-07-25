//
//  UIView.swift
//  Points
//
//  Created by Glen Hinkle on 7/23/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func constrainEdges(toView view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraintEqualToAnchor(view.topAnchor, constant: insets.top).active = true
        bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: insets.bottom).active = true
        leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: insets.left).active = true
        trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: insets.right).active = true
    }
    
    func constrainEdgesHorizontally(views: [UIView], withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) {
        
        views.enumerate().forEach { index, view in
            view.topAnchor.constraintEqualToAnchor(topAnchor).active = true
            view.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
            view.heightAnchor.constraintEqualToAnchor(heightAnchor).active = true
            
            if view == views.first {
                view.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: insets.left).active = true
            }
            else {
                view.leadingAnchor.constraintEqualToAnchor(views[index-1].trailingAnchor).active = true
            }
            
            if view == views.last {
                view.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: insets.right).active = true
            }
        }
    }
}