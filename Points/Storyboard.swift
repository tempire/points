//
//  Storyboard.swift
//  Points
//
//  Created by Glen Hinkle on 7/14/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation
import UIKit

enum Storyboard: String {
    case Main
    
    static let values = [Main]
    static var boards = [Storyboard:UIStoryboard]()
    
    func viewController<A: UIViewController>(type: A.Type) -> A {
        print("\(A.self)")
        return storyboard.instantiateViewControllerWithIdentifier("\(A.self)") as! A
    }
    
    var storyboard: UIStoryboard {
        let storyboard = Storyboard.boards[self] ?? UIStoryboard(name: rawValue, bundle: .None)
        Storyboard.boards[self] = storyboard
        return storyboard
    }
}