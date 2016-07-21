//
//  Swift.swift
//  Points
//
//  Created by Glen Hinkle on 7/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

enum Dispatch {
    case Sync
    case Async
}

infix operator ??= {
}

func ??=(inout left: Any?, right: AnyObject) -> Any {
    if left == nil {
        left = right
    }
    
    return left!
}

func ui(dispatch: Dispatch, afterDelay: Double = 0, closure: Void->Void) {
    delay(afterDelay, dispatch: dispatch, queue: dispatch_get_main_queue(), closure: closure)
}

func dispatch(queue: dispatch_queue_t, _ dispatch: Dispatch, block: Void->Void) {
    
    switch dispatch {
        
    case .Sync:
        dispatch_sync(queue, block)
        
    case .Async:
        dispatch_async(queue, block)
    }
}

func delay(delay:Double, dispatch _dispatch: Dispatch, queue: dispatch_queue_t, closure: Void->Void) {
    
    if _dispatch == .Sync && delay == 0 {
        return dispatch(queue, _dispatch, block: closure)
    }
    
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        queue, {
            dispatch(queue, _dispatch, block: closure)
        }
    )
}

