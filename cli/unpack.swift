//
//  unpack.swift
//  MessagePack2.0
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

public extension NSData {
    
    /**
     Unpack data to an array of unpacked `NSData`
     - Parameter amount: Specific the amount of data going to unpack, the unpacking will stop at specified amount. Left it to `nil` will automatically unpack all the data
     - Parameter returnRemainingBytes: Return remaining bytes if error occurs or reached specified amount of unpacked objects, remaining bytes will be the last object in the returning array, default is `false`
     - returns: An `NSData` array packed with unpacked data, if return_remainingBytes is `ture`, the remaining bytes will store as the last object in the array
     */
    public func itemsUnpacked(forAmount amount: Int? = nil, returnRemainingBytes: Bool = false) throws -> [NSData] {
        var length: Int = 0
        return try itemsAndTypesAfterUnpack( forAmount: amount, returnRemainingBytes: returnRemainingBytes, bytesHandled: &length).0
    }
    
    /**
     Unpack data to an array of unpacked `NSData`
     - Parameter amount: Specific the amount of data going to unpack, the unpacking will stop at specified amount. Left it to `nil` will automatically unpack all the data
     - Parameter returnRemainingBytes: Return remaining bytes if error occurs or reached specified amount of unpacked objects, remaining bytes will be the last object in the returning array, default is `false`
     - returns: A duple of an `NSData` array packed with unpacked data and an array of `[DataType]` which contains corresponding type for each data in `[NSData]` unpacked, if return_remainingBytes is `ture`, the  remaining bytes will store as the last object in the array
     */
    public func dataAndTypesUnpacked(forAmount amount: Int? = nil, returnRemainingBytes: Bool = false) throws -> (data: [NSData], type: [DataTypes]) {
        var length: Int = 0
        let ret = try itemsAndTypesAfterUnpack( forAmount: amount, returnRemainingBytes: returnRemainingBytes, bytesHandled: &length)
        return ret
    }
    
    /**
     Unpack data to an array of unpacked `NSData`
     - Parameter amount: Specific the amount of data going to unpack, the unpacking will stop at specified amount. Left it to `nil` will automatically unpack all the data
     - Parameter returnRemainingBytes: Return remaining bytes if error occurs or reached specified amount of unpacked objects, remaining bytes will be the last object in the returning array, default is `false`
     - returns:  An array of duples contain an unpacked data as `NSData` and its type as `DataType`, if return_remainingBytes is `ture`, the  remaining bytes will store as the last object in the array     */
    public func arrayOfDataAndTypesUnpacked(forAmount amount: Int? = nil, returnRemainingBytes: Bool = false) throws -> [(data: NSData, type: DataTypes)] {
        var length: Int = 0
        
        var temp: [(data:  NSData, type: DataTypes)] = []
        let (data, type) = try itemsAndTypesAfterUnpack(forAmount: amount, returnRemainingBytes: returnRemainingBytes, bytesHandled: &length)

        #if swift(>=3)
        for (index, data) in data.enumerated() {
            temp.append((data: data, type: type[index]))
        }
        #else
        for (index, data) in data.enumerate() {
            temp.append((data: data, type: type[index]))
        }
        #endif
        return temp

    }
    
    #if swift(>=3)
    
    /**
     This method is only used for unpack a message pack array object
     
     - Parameter bytes: the origial data
     - Parameter index: index where the header byte of the array located at
     - Parameter count: total count of objects the array stored
     - Parameter length: the length (of bytes) of the messagepacked map will return to this instance
     - returns: An `NSData` that can convert to `NSArray`, if the return is nil, it identicated there's something wrong while unpacking objects inside the array
     */
    private static func parsePackedArray(_ bytes: NSData, index: Int, count: Int, length: inout Int) ->  NSData?
    {
        var temp_byte_array: ByteArray = bytes.byteArrayValue()        //byte array representation of data
        //        temp_byte_array.removeRange(Range<Int>(start: 0, end: index))   //remove the bytes before the index...
        temp_byte_array.removeSubrange(Range<Int>(0..<index)) //swift 3
        
        let data_buffer = try? temp_byte_array.dataValue().itemsAndTypesAfterUnpack(forAmount: count, returnRemainingBytes: false, bytesHandled: &length).0
        
        return (data_buffer == nil) ? nil : NSKeyedArchiver.archivedData(withRootObject: data_buffer! as NSArray)
    }
    
    /**
     This method is only used for unpack a message pack map object
     
     - Parameter bytes: the origial data
     - Parameter index: index where the header byte of the map located at
     - Parameter count: total count of objects the map stored
     - Parameter length: the length (of bytes) of the messagepacked map will return to this instance
     - returns: An `NSData` that can convert to `NSDictionary`, if the return is nil, it identicated there's something wrong while unpacking objects inside the array
     */
    private static func parsePackedMap(_ bytes: NSData, index: Int, count: Int, length: inout Int)   ->  NSData?
    {
        var temp_byte_array = bytes.byteArrayValue()            //byte array representation of data
        var dict: Dictionary<NSData, NSData>? = [:]                      //buffer
        
        //        temp_byte_array.removeRange(Range<Int>(start: 0, end: index))   //remove the bytes before index
        temp_byte_array.removeSubrange(0..<index) //swift 3
        
        let data_buffer = try? temp_byte_array.dataValue().itemsAndTypesAfterUnpack(forAmount: count * 2, returnRemainingBytes: false, bytesHandled: &length).0 // 1 key, 1 value = 2 object at a count
        
        while (data_buffer == nil) {
            return nil
        }
        
        for i in stride(from: 0, to: count * 2, by: 2) {                       //Matching key and value
            dict![data_buffer![i]] = data_buffer![i + 1]
        }
        
        return (data_buffer == nil) ? nil : NSKeyedArchiver.archivedData(withRootObject: dict! as NSDictionary)
    }
    
    #else
    /**
     This method is only used for unpack a message pack array object
     
     - Parameter bytes: the origial data
     - Parameter index: index where the header byte of the array located at
     - Parameter count: total count of objects the array stored
     - Parameter length: the length (of bytes) of the messagepacked map will return to this instance
     - returns: An `NSData` that can convert to `NSArray`, if the return is nil, it identicated there's something wrong while unpacking objects inside the array
     */
    private static func parsePackedArray(_ bytes: NSData, index: Int, count: Int, inout length: Int) ->  NSData?
    {
        var temp_byte_array: ByteArray = bytes.byteArrayValue()        //byte array representation of data
        //        temp_byte_array.removeRange(Range<Int>(start: 0, end: index))   //remove the bytes before the index...
        temp_byte_array.removeRange(Range<Int>(0..<index)) //swift 3
        
        let data_buffer = try? temp_byte_array.dataValue().itemsAndTypesAfterUnpack(forAmount: count, returnRemainingBytes: false, bytesHandled: &length).0
        
        return (data_buffer == nil) ? nil : NSKeyedArchiver.archivedDataWithRootObject(data_buffer! as NSArray)
    }
    
    /**
     This method is only used for unpack a message pack map object
     
     - Parameter bytes: the origial data
     - Parameter index: index where the header byte of the map located at
     - Parameter count: total count of objects the map stored
     - Parameter length: the length (of bytes) of the messagepacked map will return to this instance
     - returns: An `NSData` that can convert to `NSDictionary`, if the return is nil, it identicated there's something wrong while unpacking objects inside the array
     */
    private static func parsePackedMap(_ bytes: NSData, index: Int, count: Int, inout length: Int) ->  NSData?
    {
        var temp_byte_array = bytes.byteArrayValue()            //byte array representation of data
        var dict: Dictionary<NSData, NSData>? = [:]                      //buffer
        
        //        temp_byte_array.removeRange(Range<Int>(start: 0, end: index))   //remove the bytes before index
        temp_byte_array.removeRange(0..<index) //swift 3
        
        let data_buffer = try? temp_byte_array.dataValue().itemsAndTypesAfterUnpack(forAmount: count * 2, returnRemainingBytes: false, bytesHandled: &length).0 // 1 key, 1 value = 2 object at a count
        
        while (data_buffer == nil) {
            return nil
        }
        
        for i in 0.stride(to: count * 2, by: 2) {                       //Matching key and value
            dict![data_buffer![i]] = data_buffer![i + 1]
        }
        
        return (data_buffer == nil) ? nil : NSKeyedArchiver.archivedDataWithRootObject(dict! as NSDictionary)
    }
    #endif
    
    /**
     a handler used in `unpackBySetsWith...` function
     - Parameter unpackedData: unpacked data for the session
     - Parameter isLast: if this is the last session
     - returns: Ask the unpacker to proceed by return `true` and stop by return `false`
     */
    public typealias UnpackHandler = (unpackedData: [NSData], isLast: Bool) -> Bool
    
    /**
     Unpack data and execute handler every constant amount of objects
     - Parameter objectsInEachSet: your handler will called when it finished unpack the multiplier of this amount of object. For example, if you set this parameter to 3, the handler will called when it finished unpack the 3rd, 6th, 9th... object
     - Parameter numberOfSetsToUnpack: Optional paramenter, specify how many sets to unpack
     - Parameter handlerForEachSet: This handler will call whenever `objectsInEachSet` amount of objects unpacked, it will also call when the unpacker reaches the last object. when reaches the last amount specified (if any) or the last object, `isLast` parameter will be `true`. for the return value, Return `true` if you want to proceed and `false` to stop the unpacker
    */
    public func unpackByGroupsWith(objectsInEachGroup: Int, numberOfSetsToUnpack setsCount: Int? = nil, handlerForEachGroup handler: UnpackHandler) throws {
        var i = 0
        let length = self.byteArrayValue().count
        var count = 0
        while (i < length) {
            
                let dataArray = try itemsAndTypesAfterUnpack(fromIndex: i, forAmount: objectsInEachGroup, returnRemainingBytes: false, bytesHandled: &i).0
                count += 1
                if !handler(unpackedData: dataArray, isLast: (i == length) ||  count == setsCount) || count == setsCount {
                    break
                }
            
        }
    }
    
    
    //MARK: God-like function for unpacking
    #if swift(>=3)
    
    private func itemsAndTypesAfterUnpack(fromIndex i_: Int = 0, forAmount amount: Int? = nil, returnRemainingBytes: Bool = false, bytesHandled len: inout Int) throws -> ([NSData], [DataTypes])
//    private func unpack(startIndex i_: Int = 0, specific_amount amount: Int? = nil, return_remainingBytes: Bool = false, dataLengthOutput len: inout Int) throws -> ([NSData], [DataTypes])
    {
        var byte_array: ByteArray = self.byteArrayValue()
        var packedObjects         = [NSData]()
        var dataTypes             = [DataTypes]()
        var i: Int                =     i_
        let _singleByteSize       =     1
        let _8bitDataSize         =     1
        let _16bitDataSize        =     2
        let _32bitDataSize        =     4
        let _64bitDataSize        =     8
        
        while (i < byte_array.count) {
            var shift: Int!, dataSize: Int!
            var type: DataTypes = .fixstr
            var time_to_break: Bool = false
            var continue_           = false
            var controlFlowState: control_flow = .None
            
            let _fixStrDataMarkupSize    =  Int(byte_array[i] ^ 0b101_00000)/sizeof(UInt8)
            let _fixArrayDataCount       =  Int(byte_array[i] ^ 0b1001_0000)/sizeof(UInt8)
            let _fixMapCount             =  Int(byte_array[i] ^ 0b1000_0000)/sizeof(UInt8)
            
            
            let _8bitMarkupDataSize      =  byte_array.count - (i+1) >= 1 ?
                Int(byte_array[i + 1])  : 0// (i + 1) : the next byte of prefix byte, which is the size byte
            
            let _16bitMarkupDataSize     =  byte_array.count - (i+2) >= 2 ?
                byte_array[i+1]._16bitValue(jointWith: byte_array[i+2]) : 0
            
            let _32bitMarkupDataSize     =  byte_array.count - (i+3) >= 3 ?
                byte_array[i+1]._32bitValue(joinWith: byte_array[i+2],
                                            and: byte_array[i+3])       : 0
            
            //helper method
            func addRemainingBytes() {
                if returnRemainingBytes {
                    var remainingBytes = ByteArray(count: (byte_array.count - i), repeatedValue: 0)
                    //self.getBytes(&remainingBytes, range: NSRange.init(Range<Int>(start: i, end: byte_array.count)))
                    self.getBytes(&remainingBytes, range: NSRange.init(Range<Int>(i..<byte_array.count)))
                    packedObjects.append(remainingBytes.dataValue())
                    dataTypes.append(.remainingBytes)
                }
            }
            
            //helper method
            func checkIfEnd(_ data: NSData?, shift: Int) throws
            {
                if data == nil {throw PackingError.dataEncodingError}
                else {
                    packedObjects.append(data!)
                    i += shift
                    if amount != nil && packedObjects.count == amount {
                        if returnRemainingBytes {
                            addRemainingBytes()
                        }
                        controlFlowState = .Break
                    } else {
                        controlFlowState = .Continue
                    }
                }
            }
            
            switch byte_array[i] {
                
            //Nil
            case 0xc0:
                type = .`nil`
                dataSize = _singleByteSize
                try checkIfEnd([0xc0].dataValue(), shift: dataSize)
                
            case 0xc2:
                type = .bool
                dataSize = _singleByteSize
                
                try checkIfEnd([0x00].dataValue(), shift: dataSize)
                
            case 0xc3:
                type = .bool
                dataSize = _singleByteSize
                
                try checkIfEnd([0x01].dataValue(), shift: dataSize)
                
            //bool
            case 0xc2, 0xc3:
                type = .bool            ;    dataSize = _singleByteSize
                
            //bin
            case 0xc4:  type = .bin8    ;    dataSize = _8bitMarkupDataSize
            case 0xc5:  type = .bin16   ;    dataSize = _16bitMarkupDataSize
            case 0xc6:  type = .bin32   ;    dataSize = _32bitMarkupDataSize
                
            //float
            case 0xca:  type = .float32 ;    dataSize = _32bitDataSize
            case 0xcb:  type = .float64 ;    dataSize = _64bitDataSize
                
            //uint
            case 0xcc:  type = .uInt8   ;    dataSize = _8bitDataSize
            case 0xcd:  type = .uInt16  ;    dataSize = _16bitDataSize
            case 0xce:  type = .uInt32  ;    dataSize = _32bitDataSize
            case 0xcf:  type = .uInt64  ;    dataSize = _64bitDataSize
                
                //int
                
            case 0...0b01111111:
                type = .fixInt          ;    dataSize = _singleByteSize
            case 0b11100000..<0b11111111:
                type = .fixNegativeInt  ;    dataSize = _singleByteSize
            case 0xd0:  type = .int8    ;    dataSize = _8bitDataSize
            case 0xd1:  type = .int16   ;    dataSize = _16bitDataSize
            case 0xd2:  type = .int32   ;    dataSize = _32bitDataSize
            case 0xd3:  type = .int64   ;    dataSize = _64bitDataSize
                
                
            //String
            case 0b101_00000...0b101_11111:
                type = .fixstr  ;    dataSize = _fixStrDataMarkupSize
            case 0xd9:  type = .str8bit;    dataSize = _8bitMarkupDataSize
            case 0xda:  type = .str16bit;   dataSize = _16bitMarkupDataSize
            case 0xdb:  type = .str32bit;   dataSize = _32bitMarkupDataSize
                
            //array
            case 0b10010000...0b10011111:
                let count                  = _fixArrayDataCount
                var length: Int            = 0
                let data                   = NSData.parsePackedArray(self, index: i + 1, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1)
                dataTypes.append(.fixarray)
                
                
            case 0xdc:
                let count                   = _16bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedArray(self, index: i + 1 + 2, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 2)
                dataTypes.append(.array16)
                
            case 0xdd:
                let count                   = _32bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedArray(self, index: i + 1 + 4, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 4)
                dataTypes.append(.array32)
            //map
            case 0b10000000...0b10001111:
                let count                   = _fixMapCount
                var length:Int              = 0
                let data                    = NSData.parsePackedMap(self, index: i + 1, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1)
                dataTypes.append(.fixmap)
                
            case 0xde:
                let count                   = _16bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedMap(self, index: i + 1 + 2, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 2)
                dataTypes.append(.map16)
            case 0xdf:
                let count                   = _32bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedMap(self, index: i + 1 + 4, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 4)
                dataTypes.append(.map32)
            default: throw UnpackingError.unknownDataTypeUndifinedPrefix
            }
            
            if case controlFlowState = control_flow.Break {
                break
            }
            
            if case controlFlowState = control_flow.Continue {
                continue
            }
            
            dataTypes.append(type)
            
            shift = try type.getDataPrefixSize()
            var temp: ByteArray     = ByteArray(count: dataSize, repeatedValue: 0)
            self.getBytes(&temp, range: NSRange.init(Range<Int>(i+shift..<i+shift+dataSize)))
            switch type {
            //Since message pack is using big edian, we have to flip the bytes to make it useful
            case .uInt8, .uInt16, .uInt32, .uInt64,
                 .int8,  .int16,  .int32,  .int64, .float64, .float32:
                temp.flip()
                
            case .fixNegativeInt:
                //
                let x   = [temp[0] ^ 0b11100000].dataValue()
                var n_i = -x.castToInt
                temp[0] = NSData(bytes: &n_i, length: 1).byteArray[0]
                
            default: break
            }
            
            packedObjects.append(temp.dataValue())
            
            i += dataSize + shift
            
            //when `packedObject` stored enough values or entered an infinity loop because of bad data, break
            if (amount != nil && packedObjects.count == amount) || (dataSize + shift) == 0 {
                if returnRemainingBytes {addRemainingBytes()}
                else if (dataSize + shift == 0) {
                    throw UnpackingError.invaildDataFormat
                }
                break
            }
        }
        
        len = i
        return (packedObjects, dataTypes)
    }
    #else
    /**
     Unpack data to an array of unpacked `NSData`
     - Parameter amount: Specific the amount of data going to unpack, the unpacking will stop at specified amount. Left it to `nil` will automatically unpack all the data
     - Parameter returnRemainingBytes: Return remaining bytes if error occurs or reached specified amount of unpacked objects, remaining bytes will be the last object in the returning array, default is `false`
     - Parameter dataLengthOutout: the length (of bytes) of the unpacker handled will output to here
     - returns: An `NSData` array packed with unpacked data, if return_remainingBytes is `ture`, the remaining bytes will store as the last object in the array
     */
    private func itemsAndTypesAfterUnpack(fromIndex i_: Int = 0, forAmount amount: Int? = nil, returnRemainingBytes: Bool = false, inout bytesHandled len: Int) throws -> ([NSData], [DataTypes])
//    private func unpack(startIndex i_: Int = 0, specific_amount amount: Int? = nil, return_remainingBytes: Bool = false, inout dataLengthOutput len: Int) throws -> ([NSData], [DataTypes])
    {
        var byte_array: ByteArray = self.byteArrayValue()
        var packedObjects         = [NSData]()
        var dataTypes             = [DataTypes]()
        var i: Int                =     i_
        let _singleByteSize       =     1
        let _8bitDataSize         =     1
        let _16bitDataSize        =     2
        let _32bitDataSize        =     4
        let _64bitDataSize        =     8
        
        while (i < byte_array.count) {
            var shift: Int!, dataSize: Int!
            var type: DataTypes = .fixstr
            var time_to_break: Bool = false
            var continue_           = false
            var controlFlowState: control_flow = .None
            
            let _fixStrDataMarkupSize    =  Int(byte_array[i] ^ 0b101_00000)/sizeof(UInt8)
            let _fixArrayDataCount       =  Int(byte_array[i] ^ 0b1001_0000)/sizeof(UInt8)
            let _fixMapCount             =  Int(byte_array[i] ^ 0b1000_0000)/sizeof(UInt8)
            
            
            let _8bitMarkupDataSize      =  byte_array.count - (i+1) >= 1 ?
                Int(byte_array[i + 1])  : 0// (i + 1) : the next byte of prefix byte, which is the size byte
            
            let _16bitMarkupDataSize     =  byte_array.count - (i+2) >= 2 ?
                byte_array[i+1]._16bitValue(jointWith: byte_array[i+2]) : 0
            
            let _32bitMarkupDataSize     =  byte_array.count - (i+3) >= 3 ?
                byte_array[i+1]._32bitValue(joinWith: byte_array[i+2],
                                            and: byte_array[i+3])       : 0
            
            //helper method
            func addRemainingBytes() {
                if returnRemainingBytes {
                    var remainingBytes = ByteArray(count: (byte_array.count - i), repeatedValue: 0)
                    //self.getBytes(&remainingBytes, range: NSRange.init(Range<Int>(start: i, end: byte_array.count)))
                    self.getBytes(&remainingBytes, range: NSRange.init(Range<Int>(i..<byte_array.count)))
                    packedObjects.append(remainingBytes.dataValue())
                    dataTypes.append(.remainingBytes)
                }
            }
            
            //helper method
            func checkIfEnd(_ data: NSData?, shift: Int) throws
            {
                if data == nil {throw PackingError.dataEncodingError}
                else {
                    packedObjects.append(data!)
                    i += shift
                    if amount != nil && packedObjects.count == amount {
                        if returnRemainingBytes {
                            addRemainingBytes()
                        }
                        controlFlowState = .Break
                    } else {
                        controlFlowState = .Continue
                    }
                }
            }
            
            switch byte_array[i] {
                
            //Nil
            case 0xc0:
                type = .`nil`
                dataSize = _singleByteSize
                try checkIfEnd([0xc0].dataValue(), shift: dataSize)
                
            case 0xc2:
                type = .bool
                dataSize = _singleByteSize
                
                try checkIfEnd([0x00].dataValue(), shift: dataSize)
                
            case 0xc3:
                type = .bool
                dataSize = _singleByteSize
                
                try checkIfEnd([0x01].dataValue(), shift: dataSize)
                
            //bool
            case 0xc2, 0xc3:
                type = .bool            ;    dataSize = _singleByteSize
                
            //bin
            case 0xc4:  type = .bin8    ;    dataSize = _8bitMarkupDataSize
            case 0xc5:  type = .bin16   ;    dataSize = _16bitMarkupDataSize
            case 0xc6:  type = .bin32   ;    dataSize = _32bitMarkupDataSize
                
            //float
            case 0xca:  type = .float32 ;    dataSize = _32bitDataSize
            case 0xcb:  type = .float64 ;    dataSize = _64bitDataSize
                
            //uint
            case 0xcc:  type = .uInt8   ;    dataSize = _8bitDataSize
            case 0xcd:  type = .uInt16  ;    dataSize = _16bitDataSize
            case 0xce:  type = .uInt32  ;    dataSize = _32bitDataSize
            case 0xcf:  type = .uInt64  ;    dataSize = _64bitDataSize
                
                //int
                
            case 0...0b01111111:
                type = .fixInt          ;    dataSize = _singleByteSize
            case 0b11100000..<0b11111111:
                type = .fixNegativeInt  ;    dataSize = _singleByteSize
            case 0xd0:  type = .int8    ;    dataSize = _8bitDataSize
            case 0xd1:  type = .int16   ;    dataSize = _16bitDataSize
            case 0xd2:  type = .int32   ;    dataSize = _32bitDataSize
            case 0xd3:  type = .int64   ;    dataSize = _64bitDataSize
                
                
            //String
            case 0b101_00000...0b101_11111:
                type = .fixstr  ;    dataSize = _fixStrDataMarkupSize
            case 0xd9:  type = .str8bit;    dataSize = _8bitMarkupDataSize
            case 0xda:  type = .str16bit;   dataSize = _16bitMarkupDataSize
            case 0xdb:  type = .str32bit;   dataSize = _32bitMarkupDataSize
                
            //array
            case 0b10010000...0b10011111:
                let count                  = _fixArrayDataCount
                var length: Int            = 0
                let data                   = NSData.parsePackedArray(self, index: i + 1, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1)
                dataTypes.append(.fixarray)
                
                
            case 0xdc:
                let count                   = _16bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedArray(self, index: i + 1 + 2, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 2)
                dataTypes.append(.array16)
                
            case 0xdd:
                let count                   = _32bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedArray(self, index: i + 1 + 4, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 4)
                dataTypes.append(.array32)
            //map
            case 0b10000000...0b10001111:
                let count                   = _fixMapCount
                var length:Int              = 0
                let data                    = NSData.parsePackedMap(self, index: i + 1, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1)
                dataTypes.append(.fixmap)
                
            case 0xde:
                let count                   = _16bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedMap(self, index: i + 1 + 2, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 2)
                dataTypes.append(.map16)
            case 0xdf:
                let count                   = _32bitMarkupDataSize
                var length: Int             = 0
                let data                    = NSData.parsePackedMap(self, index: i + 1 + 4, count: count, length: &length)
                try checkIfEnd(data, shift: length + 1 + 4)
                dataTypes.append(.map32)
            default: throw UnpackingError.unknownDataTypeUndifinedPrefix
            }
            
            if case controlFlowState = control_flow.Break {
                break
            }
            
            if case controlFlowState = control_flow.Continue {
                continue
            }
            
            dataTypes.append(type)
            
            shift = try type.getDataPrefixSize()
            var temp: ByteArray     = ByteArray(count: dataSize, repeatedValue: 0)
            self.getBytes(&temp, range: NSRange.init(Range<Int>(i+shift..<i+shift+dataSize)))
            switch type {
            //Since message pack is using big edian, we have to flip the bytes to make it useful
            case .uInt8, .uInt16, .uInt32, .uInt64,
                 .int8,  .int16,  .int32,  .int64, .float64, .float32:
                temp.flip()
                
            case .fixNegativeInt:
                //
                let x   = [temp[0] ^ 0b11100000].dataValue()
                var n_i = -x.castToInt
                temp[0] = NSData(bytes: &n_i, length: 1).byteArray[0]
                
            default: break
            }
            
            packedObjects.append(temp.dataValue())
            
            i += dataSize + shift
            
            //when `packedObject` stored enough values or entered an infinity loop because of bad data, break
            if (amount != nil && packedObjects.count == amount) || (dataSize + shift) == 0 {
                if returnRemainingBytes {addRemainingBytes()}
                else if (dataSize + shift == 0) {
                    throw UnpackingError.invaildDataFormat
                }
                break
            }
        }
        
        len = i
        return (packedObjects, dataTypes)
    }
    #endif
}

public extension NSData {
    
    public func unpackAsyncForEach(priority: dispatch_queue_priority_t, amount: Int? = nil, competitionHandler: (data: NSData, type: DataTypes, atIndex: Int) -> Void) {
        #if swift(>=3)

            let queue = DispatchQueue.global()
            queue.async(execute: {
                var i = 0
                let parsed = try? parseData(messagePackedBytes: self.byteArray,specific_amount: amount, dataLengthOutput: &i)
                if let parsed = parsed {
                    let group = DispatchGroup()
                    let que = DispatchQueue.global()
                    for (index, s) in parsed.enumerated() {
                        que.async(group: group, qos: priority, flags: DispatchWorkItemFlags(rawValue: UInt(0)), execute: {
                            let range = NSMakeRange(s.0.lowerBound, s.0.upperBound - s.0.lowerBound)
                            var buf = ByteArray(count: range.length, repeatedValue: 0)
                            self.getBytes(&buf, range: range)
                            let data = try! NSData(bytes: buf, length: range.length).itemsUnpacked(forAmount: 1, returnRemainingBytes: false)[0]
                            competitionHandler(data: data, type: s.1, atIndex: index)
                        })
                    }
                }
            })
        #else
        
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            var i = 0;
            let parsed = try? parseData(messagePackedBytes: self.byteArray,specific_amount: amount, dataLengthOutput: &i)
        
            if let parsed = parsed {
                
                let group = dispatch_group_create()
                
                for (index, s) in parsed.enumerate() {
                    dispatch_group_async(group, dispatch_get_global_queue(priority, 0), {
                        let range = NSMakeRange(s.0.startIndex, s.0.endIndex - s.0.startIndex)
                        var buf = ByteArray(count: range.length, repeatedValue: 0)
                        self.getBytes(&buf, range: range)
                        let data = try! NSData(bytes: buf, length: range.length).itemsUnpacked(forAmount: 1, returnRemainingBytes: false)[0]
                        competitionHandler(data: data, type: s.1, atIndex: index)
                    })
                }
            }
        }
            
        #endif
    }
    
    
    public func unpackAsync(priority: dispatch_queue_priority_t, amount: Int? = nil, competitionHandler: ([NSData]) -> Void ) {
        #if swift(>=3)
            
            DispatchQueue.global().async(execute: {
                var i = 0
                let parsed = try? parseData(messagePackedBytes: self.byteArray,specific_amount: amount, dataLengthOutput: &i)
                
                if let parsed = parsed {
                    
                    var output = [NSData](count: 100, repeatedValue: NSData())
                    let group = DispatchGroup()
                    
                    for (index, s) in parsed.enumerated() {
                        DispatchQueue.global().async(group: group, qos: priority, flags: DispatchWorkItemFlags(rawValue: UInt(0)), execute: {
                            let range = NSMakeRange(s.0.lowerBound, s.0.upperBound - s.0.lowerBound)
                            var buf = ByteArray(count: range.length, repeatedValue: 0)
                            self.getBytes(&buf, range: range)
                            let data = try! NSData(bytes: buf, length: range.length).itemsUnpacked(forAmount: 1, returnRemainingBytes: false)[0]
                            output[index] = data
                        })
                    }
                    
                    group.notify(queue: DispatchQueue.global(), execute: {
                        competitionHandler(output)
                    })
                    
                }
            })
        #else
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            var i = 0;
            let parsed = try? parseData(messagePackedBytes: self.byteArray,specific_amount: amount, dataLengthOutput: &i)
            
            if let parsed = parsed {
                
                var output = [NSData](count: 100, repeatedValue: NSData())
                let group = dispatch_group_create()
                
                for (index, s) in parsed.enumerate() {
                    dispatch_group_async(group, dispatch_get_global_queue(priority, 0), {
                        let range = NSMakeRange(s.0.startIndex, s.0.endIndex - s.0.startIndex)
                        var buf = ByteArray(count: range.length, repeatedValue: 0)
                        self.getBytes(&buf, range: range)
                        let data = try! NSData(bytes: buf, length: range.length).itemsUnpacked(forAmount: 1, returnRemainingBytes: false)[0]
                        output[index] = data
                    })
                }
                
                dispatch_group_notify(group, dispatch_get_global_queue(priority, 0), {
                    competitionHandler(output)
                })
                
            }
        }
        #endif
    }
}




