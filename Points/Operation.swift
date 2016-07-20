//
//  Operation.swift
//  Points
//
//  Created by Glen Hinkle on 7/4/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

typealias OperationBlock = (operation: Operation)->()

typealias co = ConcurrentOperation
typealias so = SerialOperation
typealias bo = BlockOperation

class BlockOperation: Operation {
    var block: OperationBlock
    
    init (_ block: OperationBlock) {
        self.block = block
        
        super.init()
        
        self.name = "Block Operation \(NSUUID().UUIDString)"
    }
    
    override func start() {
        super.start()
        if finished { return }
        
        block(operation: self)
    }
}

class ConcurrentOperation: GroupOperation {
    override weak var operationQueue: NSOperationQueue? {
        didSet {
            for op in queue.operations {
                if let op = op as? Operation { op.operationQueue = operationQueue }
            }
        }
    }
    
    init (_ name: String, operations: [Operation]) {
        super.init()
        
        self.name = name
        
        queue.suspended = true
        
        if operations.count > 0 { schedule(operations) }
    }
    
    convenience init (_ name: String, _ operations: Operation...) {
        let name = "Concurrent Operation \(NSUUID().UUIDString)"
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: Operation...) {
        let name = "Concurrent Operation \(NSUUID().UUIDString)"
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: [Operation]) {
        let name = "Concurrent Operation \(NSUUID().UUIDString)"
        self.init(name, operations: operations)
    }
    
    func schedule(operations: [Operation]) {
        queue.addOperations(operations, waitUntilFinished: false)
        queue.addOperationWithBlock {
            self.state = .Finished
        }
        
        let lastOp = queue.operations.last as! NSBlockOperation
        for op in queue.operations.filter({ [unowned lastOp] in $0 !== lastOp }) {
            lastOp.addDependency(op)
        }
    }
    
}

class SerialOperation: GroupOperation {
    override weak var operationQueue: NSOperationQueue? {
        didSet {
            // Do not count last NSBlockOperation...may be able to be removed with waitUntilFinished
            for op in queue.operations[0..<queue.operations.count-1] {
                if let op = op as? Operation { op.operationQueue = operationQueue }
            }
        }
    }
    
    init (_ name: String, operations: [Operation]) {
        super.init()
        
        self.name = name
        
        queue.suspended = true
        
        if operations.count > 0 { schedule(operations) }
    }
    
    convenience init (_ name: String, _ operations: Operation...) {
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: Operation...) {
        let name = "Serial Operation \(NSUUID().UUIDString)"
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: [Operation]) {
        let name = "Serial Operation \(NSUUID().UUIDString)"
        self.init(name, operations: operations)
    }
    
    func schedule(operations: [Operation]) {
        //var index = 0
        
        queue.addOperations(
            operations.reduce([Operation]()) { a, b in
                if a.count > 0 {
                    b.addDependency(a.last!)
                }
                
                return a + [b]
            },
            waitUntilFinished: false
        )
        
        queue.addOperationWithBlock { self.state = .Finished }
        
        queue.operations.last!.addDependency(queue.operations[queue.operations.count - 2])
    }
}

class GroupOperation: Operation {
    let queue = NSOperationQueue()
    //func schedule(operations: [Operation]) { }
    
    override func start() {
        super.start()
        
        queue.suspended = false
    }
}

class Operation: NSOperation {
    weak var operationQueue: NSOperationQueue?
    
    internal var completion: (Operation->Void)?
    
    // MARK: Types
    
    enum State {
        case Ready, Executing, Finished, Cancelled, Paused
        func keyPath() -> String {
            switch self {
            case Ready: return "isReady"
            case Executing: return "isExecuting"
            case Finished: return "isFinished"
            case Cancelled: return "isCancelled"
            case Paused: return "isPaused"
            }
        }
    }
    
    
    // MARK: Properties
    
    var state = State.Ready {
        willSet {
            willChangeValueForKey(newValue.keyPath())
            willChangeValueForKey(state.keyPath())
        }
        didSet {
            didChangeValueForKey(oldValue.keyPath())
            didChangeValueForKey(state.keyPath())
        }
    }
    
    override func willChangeValueForKey(key: String) {
        super.willChangeValueForKey(key)
    }
    
    
    // MARK: NSOperation
    
    var paused: Bool {
        get {
            return state == .Paused
        }
        set {
            state = newValue ? .Paused : .Ready
        }
    }
    
    override var ready: Bool { return super.ready && state == .Ready }
    override var executing: Bool { return state == .Executing }
    override var finished: Bool { return state == .Finished }
    override var asynchronous: Bool { return true }
    
    override func start() {
        state = cancelled ? .Finished : .Executing
        
        if name == nil {
            name = "\(self.dynamicType)".componentsSeparatedByString(".").last
        }
    }
    
    
    // MARK: NSOperationQueue management
    
    func cancelOperationQueue() {
        self.state = .Cancelled
    }
    
    func done() {
        completion?(self)
        state = .Finished
    }
    
    func next() {
        done()
    }
}