//
//  PopTransitionController.swift
//  Points
//
//  Created by Glen Hinkle on 8/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

class PopTransitionController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            containerView = transitionContext.containerView() {
            
            toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
            containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
            
            UIView.animateWithDuration(
                0.3,
                
                animations: {
                    fromVC.view.frame = CGRect(
                        x: toVC.view.frame.origin.x + toVC.view.frame.width, y: toVC.view.frame.origin.y,
                        width: toVC.view.frame.width, height: toVC.view.frame.height
                    ) },
                
                completion: { finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                }
            )
        }
    }
}