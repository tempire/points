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

func ui(dispatch: Dispatch, block: Void->Void) {
    
    switch dispatch {
        
    case .Sync:
        dispatch_sync(dispatch_get_main_queue(), block)
        
    case .Async:
        dispatch_async(dispatch_get_main_queue(), block)
    }
}

func dispatch(qos: qos_class_t, _ dispatch: Dispatch, block: Void->Void) {
    
    switch dispatch {
        
    case .Sync:
        dispatch_sync(dispatch_get_global_queue(qos, 0), block)
        
    case .Async:
        dispatch_async(dispatch_get_global_queue(qos, 0), block)
    }
}