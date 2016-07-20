//
//  JSON.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation


// MARK: - JSONError

public enum JSONError: ErrorType, CustomStringConvertible {
    case UnexpectedError(NSError)
    case JSONNotFound
    case KeyNotFound(key: JSONKeyType, raw: Any)
    case NullValue(key: JSONKeyType)
    case TypeMismatch(expected: Any, actual: Any)
    case TypeMismatchWithKey(key: JSONKeyType, expected: Any, actual: Any, raw: Any)
    
    var nsErrorCode: NSError.Domain.Code {
        switch self {
        case .UnexpectedError(_):
            return .JSON(0)
            
        case .JSONNotFound:
            return .JSON(1)
            
        case .KeyNotFound(_):
            return .JSON(2)
            
        case .NullValue(_):
            return .JSON(3)
            
        case .TypeMismatch(_):
            return .JSON(4)
            
        case .TypeMismatchWithKey(_):
            return .JSON(5)
        }
    }
    
    var nsError: NSError {
        return NSError(domain: .JSON, code: nsErrorCode, message: description)
    }
    
    public var description: String {
        switch self {
        case let .UnexpectedError(error):
            return "Unexpected Error: \(error.localizedDescription)"
            
        case .JSONNotFound:
            return "JSON data not found"
            
        case let .KeyNotFound(key, raw):
            return "Key not found \(key.stringValue) in \(raw)"
            
        case let .NullValue(key):
            return "Null Value found at \(key.stringValue)"
            
        case let .TypeMismatch(expected, actual):
            return "Type mismatch. Expected type \(expected), but received '\(actual)'"
            
        case let .TypeMismatchWithKey(key, expected, actual, raw):
            return "Type mismatch. Expected \(expected) for key: \(key), but received '\(actual)' (\(raw))"
        }
    }
}


// MARK: - JSONKeyType

public protocol JSONKeyType {
    var stringValue: String { get }
}

extension String: JSONKeyType {
    public var stringValue: String {
        return self
    }
}


// MARK: - JSONValueType

public protocol JSONValueType {
    associatedtype ValueType = Self
    
    static func JSONValue(object: Any) throws -> ValueType
}

// JSONValue function for all toll-free bridge types

extension JSONValueType {
    public static func JSONValue(object: Any) throws -> ValueType {
        guard let objectValue = object as? ValueType else {
            throw JSONError.TypeMismatch(expected: ValueType.self, actual: object.dynamicType)
        }
        return objectValue
    }
}


// MARK: - JSONValueType Implementations

extension String: JSONValueType {}
extension Int: JSONValueType {}
extension UInt: JSONValueType {}
extension Float: JSONValueType {}
extension Double: JSONValueType {}
extension Bool: JSONValueType {}


extension NSData: JSONValueType {
    public static func JSONValue(object: Any) throws -> JSONObject {
        guard let data = object as? NSData, json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? JSONObject else {
            throw JSONError.JSONNotFound
        }
        
        return json
    }
}

extension NSUUID: JSONValueType {
    public static func JSONValue(object: Any) throws -> NSUUID {
        guard let string = object as? String, uuid = NSUUID(UUIDString: string) else {
            throw JSONError.JSONNotFound
        }
        
        return uuid
    }
}

extension Array where Element: JSONValueType {
    public static func JSONValue(object: Any) throws -> [Element] {
        guard let anyArray = object as? [AnyObject] else {
            throw JSONError.TypeMismatch(expected: self, actual: object.dynamicType)
        }
        return try anyArray.map { try Element.JSONValue($0) as! Element }
    }
}

extension Dictionary: JSONValueType {
    public static func JSONValue(object: Any) throws -> [Key: Value] {
        guard let objectValue = object as? [Key: Value] else {
            throw JSONError.TypeMismatch(expected: self, actual: object.dynamicType)
        }
        return objectValue
    }
}

extension NSURL: JSONValueType {
    public static func JSONValue(object: Any) throws -> NSURL {
        guard let urlString = object as? String, objectValue = NSURL(string: urlString) else {
            throw JSONError.TypeMismatch(expected: self, actual: object.dynamicType)
        }
        return objectValue
    }
}

extension NSDate: JSONValueType {
    public static func JSONValue(object: Any) throws -> NSDate {
        if let interval = object as? NSTimeInterval {
            
            // Allow for milliseconds and seconds epoch
            return NSDate(timeIntervalSince1970: interval.description.characters.count > 11 ? interval / 1000 : interval)
        }
            
        else if let string = object as? String, objectValue = NSDate(string, format: .ISO8601) {
            return objectValue
        }
        
        else if let string = object as? String, objectValue = NSDate(string, format: .WSDCEventMonth) {
            return objectValue
        }
        
        throw JSONError.TypeMismatch(expected: ValueType.self, actual: object.dynamicType)
    }
}


// MARK: JSONObjectConvertible

public protocol JSONObjectConvertible : JSONValueType {
    associatedtype ConvertibleType = Self
    var json: JSONObject { get }
    init(json: JSONObject) throws
}

protocol JSONStruct: JSONObjectConvertible { }

enum JSONResult<A: JSONStruct> {
    case Success(A)
    case Error(JSONError)
}

extension JSONObjectConvertible {
    public static func JSONValue(object: Any) throws -> ConvertibleType {
        
        guard let json = object as? JSONObject else {
            throw JSONError.TypeMismatch(expected: JSONObject.self, actual: object.dynamicType)
        }
        
        guard let value = try self.init(json: json) as? ConvertibleType else {
            throw JSONError.TypeMismatch(expected: ConvertibleType.self, actual: object.dynamicType)
        }
        
        return value
    }
    
    init(data: NSData?) throws {
        guard let data = data, json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? JSONObject else {
            throw JSONError.JSONNotFound
        }
        
        try self.init(json: json)
    }
}


// MARK: - JSONObject

public typealias JSONObject = [String: AnyObject]

extension Dictionary where Key: JSONKeyType {
    
    private func anyForKey(key: Key) throws -> Any {
        let pathComponents = key.stringValue.characters.split(".").map(String.init)
        var accumulator: Any = self
        
        for component in pathComponents {
            if let componentData = accumulator as? [Key: Value], value = componentData[component as! Key] {
                accumulator = value
                continue
            }
            
            throw JSONError.KeyNotFound(key: key, raw: accumulator)
        }
        
        if let _ = accumulator as? NSNull {
            throw JSONError.NullValue(key: key)
        }
        
        return accumulator
    }
    
    public func value<A: JSONValueType>(key: Key) throws -> A {
        let any = try anyForKey(key)
        do {
            if let result = try A.JSONValue(any) as? A {
                return result
            }
        }
        catch let error as JSONError {
            switch error {
            case .TypeMismatch(expected: _, actual: _):
                throw JSONError.TypeMismatchWithKey(key: key, expected: A.self, actual: any.dynamicType, raw: any)
                
            case .JSONNotFound:
                throw error
                
            default:
                throw error
            }
        }
        
        throw JSONError.TypeMismatchWithKey(key: key, expected: A.self, actual: any.dynamicType, raw: any)
    }
    
    public func value<A: JSONValueType>(key: Key) throws -> [A] {
        let any = try anyForKey(key)
        return try Array<A>.JSONValue(any)
    }
    
    public func value<A: JSONValueType>(key: Key) throws -> A? {
        do {
            return try value(key) as A
        }
        catch JSONError.KeyNotFound {
            return .None
        }
        catch JSONError.NullValue {
            return .None
        }
        catch {
            throw error
        }
    }
}