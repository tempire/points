//
//  JSON.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation


// MARK: - JSONError

public enum JSONError: Error, CustomStringConvertible {
    case unexpectedError(NSError)
    case jsonNotFound
    case keyNotFound(key: JSONKeyType, raw: Any)
    case nullValue(key: JSONKeyType)
    case typeMismatch(expected: Any, actual: Any)
    case typeMismatchWithKey(key: JSONKeyType, expected: Any, actual: Any, raw: Any)
    
    var nsErrorCode: NSError.Domain.Code {
        switch self {
        case .unexpectedError(_):
            return .json(0)
            
        case .jsonNotFound:
            return .json(1)
            
        case .keyNotFound(_):
            return .json(2)
            
        case .nullValue(_):
            return .json(3)
            
        case .typeMismatch(_):
            return .json(4)
            
        case .typeMismatchWithKey(_):
            return .json(5)
        }
    }
    
    var nsError: NSError {
        return NSError(domain: .json, code: nsErrorCode, message: description)
    }
    
    public var description: String {
        switch self {
        case let .unexpectedError(error):
            return "Unexpected Error: \(error.localizedDescription)"
            
        case .jsonNotFound:
            return "JSON data not found"
            
        case let .keyNotFound(key, raw):
            return "Key not found \(key.stringValue) in \(raw)"
            
        case let .nullValue(key):
            return "Null Value found at \(key.stringValue)"
            
        case let .typeMismatch(expected, actual):
            return "Type mismatch. Expected type \(expected), but received '\(actual)'"
            
        case let .typeMismatchWithKey(key, expected, actual, raw):
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
    
    static func JSONValue(_ object: Any) throws -> ValueType
}

// JSONValue function for all toll-free bridge types

extension JSONValueType {
    public static func JSONValue(_ object: Any) throws -> ValueType {
        guard let objectValue = object as? ValueType else {
            throw JSONError.typeMismatch(expected: ValueType.self, actual: type(of: (object) as AnyObject))
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


extension Data: JSONValueType {
    public static func JSONValue(_ object: Any) throws -> JSONObject {
        guard let data = object as? Data, let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONObject else {
            throw JSONError.jsonNotFound
        }
        
        return json
    }
}

extension UUID: JSONValueType {
    public static func JSONValue(_ object: Any) throws -> UUID {
        guard let string = object as? String, let uuid = UUID(uuidString: string) else {
            throw JSONError.jsonNotFound
        }
        
        return uuid
    }
}

extension Array where Element: JSONValueType {
    public static func JSONValue(_ object: Any) throws -> [Element] {
        guard let anyArray = object as? [AnyObject] else {
            throw JSONError.typeMismatch(expected: self, actual: type(of: (object) as AnyObject))
        }
        return try anyArray.map { try Element.JSONValue($0) as! Element }
    }
}

extension Dictionary: JSONValueType {
    public static func JSONValue(_ object: Any) throws -> [Key: Value] {
        guard let objectValue = object as? [Key: Value] else {
            throw JSONError.typeMismatch(expected: self, actual: type(of: (object) as AnyObject))
        }
        return objectValue
    }
}

extension Foundation.URL: JSONValueType {
    public static func JSONValue(_ object: Any) throws -> Foundation.URL {
        guard let urlString = object as? String, let objectValue = Foundation.URL(string: urlString) else {
            throw JSONError.typeMismatch(expected: self, actual: type(of: (object) as AnyObject))
        }
        return objectValue
    }
}

extension Date: JSONValueType {
    public static func JSONValue(_ object: Any) throws -> Date {

        if let interval = object as? TimeInterval {
            
            // Allow for milliseconds and seconds epoch
            return Date(timeIntervalSince1970: interval.description.characters.count > 11 ? interval / 1000 : interval)
        }
            
        else if let string = object as? String, let objectValue = Date(string, format: .iso8601) {
            return objectValue
        }
        
        else if let string = object as? String, let objectValue = Date(string, format: .wsdcEventMonth) {
            return objectValue
        }

        throw JSONError.typeMismatch(expected: ValueType.self, actual: type(of: (object) as AnyObject))
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
    case success(A)
    case error(JSONError)
}

extension JSONObjectConvertible {
    public static func JSONValue(_ object: Any) throws -> ConvertibleType {
        
        guard let json = object as? JSONObject else {
            throw JSONError.typeMismatch(expected: JSONObject.self, actual: type(of: (object) as AnyObject))
        }
        
        guard let value = try self.init(json: json) as? ConvertibleType else {
            throw JSONError.typeMismatch(expected: ConvertibleType.self, actual: type(of: (object) as AnyObject))
        }
        
        return value
    }
    
    init(data: Data?) throws {
        guard let data = data, let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONObject else {
            throw JSONError.jsonNotFound
        }
        
        try self.init(json: json)
    }
}


// MARK: - JSONObject

public typealias JSONObject = [String:Any]

extension Dictionary where Key: JSONKeyType {
    
    fileprivate func anyForKey(_ key: Key) throws -> Any {
        let pathComponents = key.stringValue.characters.split(separator: ".").map(String.init)
        var accumulator: Any = self
        
        for component in pathComponents {
            if let componentData = accumulator as? [Key: Value], let value = componentData[component as! Key] {
                accumulator = value
                continue
            }
            
            throw JSONError.keyNotFound(key: key, raw: accumulator)
        }
        
        if let _ = accumulator as? NSNull {
            throw JSONError.nullValue(key: key)
        }
        
        return accumulator
    }
    
    public func value<A: JSONValueType>(_ key: Key) throws -> A {
        let any = try anyForKey(key)
        do {
            if let result = try A.JSONValue(any) as? A {
                return result
            }
        }
        catch let error as JSONError {
            switch error {
            case .typeMismatch(expected: _, actual: _):
                throw JSONError.typeMismatchWithKey(key: key, expected: A.self, actual: type(of: (any) as AnyObject), raw: any)
                
            case .jsonNotFound:
                throw error
                
            default:
                throw error
            }
        }
        
        throw JSONError.typeMismatchWithKey(key: key, expected: A.self, actual: type(of: (any) as AnyObject), raw: any)
    }
    
    public func value<A: JSONValueType>(_ key: Key) throws -> [A] {
        let any = try anyForKey(key)
        return try Array<A>.JSONValue(any)
    }
    
    public func value<A: JSONValueType>(_ key: Key) throws -> A? {
        do {
            return try value(key) as A
        }
        catch JSONError.keyNotFound {
            return .none
        }
        catch JSONError.nullValue {
            return .none
        }
        catch {
            throw error
        }
    }
}
