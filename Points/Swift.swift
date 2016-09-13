//
//  Swift.swift
//  Points
//
//  Created by Glen Hinkle on 7/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

enum Dispatch {
    case sync
    case async
}

infix operator ??=

func ??=(left: inout Any?, right: AnyObject) -> Any {
    if left == nil {
        left = right
    }
    
    return left!
}

func ui(_ dispatch: Dispatch, afterDelay: Double = 0, closure: @escaping (Void)->Void) {
    delay(afterDelay, dispatch: dispatch, queue: DispatchQueue.main, closure: closure)
}

func dispatch(_ queue: DispatchQueue, _ dispatch: Dispatch, block: @escaping (Void)->Void) {
    
    switch dispatch {
        
    case .sync:
        queue.sync(execute: block)
        
    case .async:
        queue.async(execute: block)
    }
}

func delay(_ delay:Double, dispatch _dispatch: Dispatch, queue: DispatchQueue, closure: @escaping (Void)->Void) {
    
    if _dispatch == .sync && delay == 0 {
        return dispatch(queue, _dispatch, block: closure)
    }
    
    queue.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            dispatch(queue, _dispatch, block: closure)
        }
    )
}

