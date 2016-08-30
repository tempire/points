//
//  NVCTransition.swift
//  Points
//
//  Created by Glen Hinkle on 8/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

enum TransitionAxis {
    case Vertical
    case Horizontal
}

enum TransitionDirection {
    case Up
    case Down
    case Left
    case Right
    
    init(axis: TransitionAxis, point: CGPoint) {
        
        switch axis {
            
        case .Vertical:
            self = point.y > 0 ? Up : Down
            
        case .Horizontal:
            self = point.x < 0 ? Left : Right
        }
    }
}

/*

protocol WithInteractivePopTransition: class {
    var interactivePopTransition: UIPercentDrivenInteractiveTransition? { get set }
    func dismissViewControllerAnimated(flag: Bool, completion: (Void->Void)?)
}

extension WithInteractivePopTransition where Self: UIViewController {
    
}

enum InteractiveTransition {
    
    enum Vertical {
        
        enum Present {
            case Up(interactiveVC: WithInteractivePopTransition?)
            
            func animationController() -> GenericAnimationController {
                return GenericAnimationController(isPresenting: true)
            }
            
            func presentationController(presentedViewController presentedViewController: UIViewController, presentingViewController: UIViewController, size: CGSize?, dismissWithTap: Bool) -> GenericPresentationController {
                
                return GenericPresentationController(presentedViewController: presentedViewController, presentingViewController: presentingViewController, size: size, dismissWithTap: dismissWithTap)
            }
        }
        
        
        enum Dismiss {
            case Down(interactiveVC: WithInteractivePopTransition?)
            
            func animationController() -> GenericAnimationController {
                return GenericAnimationController(isPresenting: false)
            }
            
            func dismissGestureHandler(recognizer: UIPanGestureRecognizer) {
                
                guard case .Down(let interactiveVC) = self,
                    let vc = interactiveVC,
                    view = recognizer.view else {
                        return
                }
                
                let coords = recognizer.translationInView(view)
                let progress = coords.y / view.bounds.size.height
                let direction: TransitionDirection = coords.y < 0 ? .Up : .Down
                let quickFlickVelocity: CGFloat = 250
                
                switch recognizer.state {
                case .Began:
                    if direction == .Down {
                        vc.interactivePopTransition = UIPercentDrivenInteractiveTransition()
                        vc.dismissViewControllerAnimated(true, completion: .None)
                    }
                    
                case .Changed:
                    vc.interactivePopTransition?.updateInteractiveTransition(progress)
                    
                case .Ended, .Cancelled:
                    let containerView = view
                    
                    let exceededVelocityThreshold = recognizer.velocityInView(containerView).y > quickFlickVelocity
                    if exceededVelocityThreshold || progress > 0.5 {
                        vc.interactivePopTransition?.finishInteractiveTransition()
                        
                    }
                    else {
                        vc.interactivePopTransition?.cancelInteractiveTransition()
                    }
                    vc.interactivePopTransition = .None
                    
                default:
                    vc.interactivePopTransition?.cancelInteractiveTransition()
                    vc.interactivePopTransition = .None
                }
            }
        }
    }
}

class GenericAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    let duration: NSTimeInterval = 0.5
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        
        super.init()
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentationWithTransitionContext(transitionContext)
        }
        else {
            animateDismissalWithTransitionContext(transitionContext)
        }
    }
    
    func animatePresentationWithTransitionContext(context: UIViewControllerContextTransitioning) {
        guard let presentedController = context.viewControllerForKey(UITransitionContextToViewControllerKey),
            presentedControllerView = context.viewForKey(UITransitionContextToViewKey),
            containerView = context.containerView() else {
                return
        }
        
        presentedControllerView.frame = context.finalFrameForViewController(presentedController)
        containerView.addSubview(presentedControllerView)
        
        UIView.animateWithDuration(
            transitionDuration(context),
            delay: 0.0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.0,
            options: .AllowUserInteraction,
            animations: {
                presentedControllerView.frame.origin.y += presentedControllerView.frame.height
            },
            completion: { completed in
                context.completeTransition(completed)
            }
        )
    }
    
    func animateDismissalWithTransitionContext(context: UIViewControllerContextTransitioning) {
        guard let presentedView = context.viewForKey(UITransitionContextFromViewKey),
            containerView = context.containerView() else {
                return
        }
        
        UIView.animateWithDuration(
            transitionDuration(context),
            animations: {
                presentedView.frame.origin.y = containerView.frame.height
            },
            completion: { completed in
                context.completeTransition(completed && !context.transitionWasCancelled())
            }
        )
    }
}
*/