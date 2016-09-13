//
//  ModalPresentationController.swift
//  Points
//
//  Created by Glen Hinkle on 7/20/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

class ModalPresentationController: UIPresentationController {
    
    lazy var dimmingView: UIView = {
        let view = UIView(frame: self.containerView?.bounds ?? UIScreen.main.bounds)
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        view.alpha = 0.0
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView,
            let presentedView = presentedView else {
                return
        }
        
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)
        containerView.addSubview(presentedView)
        
        presentingViewController.transitionCoordinator?.animate(
            alongsideTransition: { context in
                self.dimmingView.alpha = 1.0
            },
            completion: .none
        )
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator?.animate(
            alongsideTransition: { context in
                self.dimmingView.alpha = 0
            },
            completion: .none
        )
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard let containerView = containerView else {
            return
        }
        
        coordinator.animate(
            alongsideTransition: { context in
                self.dimmingView.frame = containerView.bounds
                
            },
            completion: .none
        )
    }
    
    override var shouldPresentInFullscreen : Bool {
        return false
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {

        guard let containerView = containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        
        let size = presentedViewController.preferredContentSize
        let point = CGPoint(
            x: containerView.bounds.width / 2 - size.width / 2,
            y: containerView.bounds.height / 2 - size.height / 2
        )
        
        return CGRect(origin: point, size: size)
        
        /*
        
        print(presentingViewController.traitCollection.horizontalSizeClass)
        
        let width: CGFloat = presentingViewController.traitCollection.horizontalSizeClass == .Compact
            ? min(350, UIScreen.mainScreen().bounds.width - 12)
            : 400
        
        var height: CGFloat = 0
        
        height += 24 // top constraints
        height += vc.titleLabel.rect(width: width - 24 - 24)?.height ?? 0
        height += 8  // constraint between title and subtitle
        height += vc.subTitleLabel.rect(width: width - 24 - 24)?.height ?? 0
        height += 24 // bottom constraints
        height += 60 // buttons
        
        return CGRect(
            x: containerView.bounds.width / 2 - width / 2,
            y: containerView.bounds.height / 2 - height / 2,
            width: width,
            height: height
        )
         
        */
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.layer.cornerRadius = 6
    }
}
