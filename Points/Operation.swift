//
//  Operation.swift
//  Points
//
//  Created by Glen Hinkle on 7/4/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

typealias OperationBlock = (_ operation: Operation)->()

typealias co = ConcurrentOperation
typealias so = SerialOperation
typealias bo = BlockOperation

class BlockOperation: Operation {
    var block: OperationBlock
    
    init (_ block: @escaping OperationBlock) {
        self.block = block
        
        super.init()
        
        self.name = "Block Operation \(UUID().uuidString)"
    }
    
    override func start() {
        super.start()
        if isFinished { return }
        
        block(self)
    }
}

class ConcurrentOperation: GroupOperation {
    override weak var operationQueue: OperationQueue? {
        didSet {
            for op in queue.operations {
                if let op = op as? Operation { op.operationQueue = operationQueue }
            }
        }
    }
    
    init (_ name: String, operations: [Operation]) {
        super.init()
        
        self.name = name
        
        queue.isSuspended = true
        
        if operations.count > 0 { schedule(operations) }
    }
    
    convenience init (_ name: String, _ operations: Operation...) {
        let name = "Concurrent Operation \(UUID().uuidString)"
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: Operation...) {
        let name = "Concurrent Operation \(UUID().uuidString)"
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: [Operation]) {
        let name = "Concurrent Operation \(UUID().uuidString)"
        self.init(name, operations: operations)
    }
    
    func schedule(_ operations: [Operation]) {
        queue.addOperations(operations, waitUntilFinished: false)
        queue.addOperation {
            self.state = .finished
        }
        
        let lastOp = queue.operations.last as! Foundation.BlockOperation
        for op in queue.operations.filter({ [unowned lastOp] in $0 !== lastOp }) {
            lastOp.addDependency(op)
        }
    }
    
}

class SerialOperation: GroupOperation {
    override weak var operationQueue: OperationQueue? {
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
        
        queue.isSuspended = true
        
        if operations.count > 0 { schedule(operations) }
    }
    
    convenience init (_ name: String, _ operations: Operation...) {
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: Operation...) {
        let name = "Serial Operation \(UUID().uuidString)"
        self.init(name, operations: operations)
    }
    
    convenience init (_ operations: [Operation]) {
        let name = "Serial Operation \(UUID().uuidString)"
        self.init(name, operations: operations)
    }
    
    func schedule(_ operations: [Operation]) {
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
        
        queue.addOperation { self.state = .finished }
        
        queue.operations.last!.addDependency(queue.operations[queue.operations.count - 2])
    }
}

class GroupOperation: Operation {
    let queue = OperationQueue()
    //func schedule(operations: [Operation]) { }
    
    override func start() {
        super.start()
        
        queue.isSuspended = false
    }
}

class Operation: Foundation.Operation {
    weak var operationQueue: OperationQueue?
    
    internal var completion: ((Operation)->Void)?
    
    // MARK: Types
    
    enum State {
        case ready, executing, finished, cancelled, paused
        func keyPath() -> String {
            switch self {
            case .ready: return "isReady"
            case .executing: return "isExecuting"
            case .finished: return "isFinished"
            case .cancelled: return "isCancelled"
            case .paused: return "isPaused"
            }
        }
    }
    
    
    // MARK: Properties
    
    var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath())
            willChangeValue(forKey: state.keyPath())
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath())
            didChangeValue(forKey: state.keyPath())
        }
    }
    
    override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
    }
    
    
    // MARK: NSOperation
    
    var paused: Bool {
        get {
            return state == .paused
        }
        set {
            state = newValue ? .paused : .ready
        }
    }
    
    override var isReady: Bool { return super.isReady && state == .ready }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
    override var isAsynchronous: Bool { return true }
    
    override func start() {
        state = isCancelled ? .finished : .executing
        
        if name == nil {
            name = "\(type(of: self))".components(separatedBy: ".").last
        }
    }
    
    
    // MARK: NSOperationQueue management
    
    func cancelOperationQueue() {
        self.state = .cancelled
    }
    
    func done() {
        completion?(self)
        state = .finished
    }
    
    func next() {
        done()
    }
}
