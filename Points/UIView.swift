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
    
    func constrainEdges(toView view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsets.zero) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right).isActive = true
    }
    
    func constrainEdgesHorizontally(_ views: [UIView], withInsets insets: UIEdgeInsets = UIEdgeInsets.zero) {
        
        views.enumerated().forEach { index, view in
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            view.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
            
            if view == views.first {
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left).isActive = true
            }
            else {
                view.leadingAnchor.constraint(equalTo: views[index-1].trailingAnchor).isActive = true
            }
            
            if view == views.last {
                view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.right).isActive = true
            }
        }
    }
    
    func superviewMatching<A>(_ aClass: A.Type) -> A? {
        
        guard let superview = superview else {
            return .none
        }
        
        return superview as? A ?? superview.superviewMatching(aClass)
    }
}
