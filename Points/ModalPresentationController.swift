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
        let view = UIView(frame: self.containerView?.bounds ?? UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        view.alpha = 0.0
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView,
            presentedView = presentedView() else {
                return
        }
        
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)
        containerView.addSubview(presentedView)
        
        presentingViewController.transitionCoordinator()?.animateAlongsideTransition(
            { context in
                self.dimmingView.alpha = 1.0
            },
            completion: .None
        )
    }
    
    override func presentationTransitionDidEnd(completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator()?.animateAlongsideTransition(
            { context in
                self.dimmingView.alpha = 0
            },
            completion: .None
        )
    }
    
    override func dismissalTransitionDidEnd(completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        guard let containerView = containerView else {
            return
        }
        
        coordinator.animateAlongsideTransition(
            { context in
                self.dimmingView.frame = containerView.bounds
                
            },
            completion: .None
        )
    }
    
    override func shouldPresentInFullscreen() -> Bool {
        return false
    }
    
    override func frameOfPresentedViewInContainerView() -> CGRect {

        guard let containerView = containerView else {
            return super.frameOfPresentedViewInContainerView()
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
        presentedView()?.frame = frameOfPresentedViewInContainerView()
        presentedView()?.layer.cornerRadius = 6
    }
}