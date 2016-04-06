//
//  CryptoSwiftHMACModule.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 06/04/2016.
//
//

//
//  ArrayExtension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 10/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

extension Array {
    
    /** split in chunks with given chunk size */
    func chunks(chunksize:Int) -> [Array<Element>] {
        var words = [[Element]]()
        words.reserveCapacity(self.count / chunksize)
        for idx in chunksize.stride(through: self.count, by: chunksize) {
            let word = Array(self[idx - chunksize..<idx]) // this is slow for large table
            words.append(word)
        }
        let reminder = Array(self.suffix(self.count % chunksize))
        if (reminder.count > 0) {
            words.append(reminder)
        }
        return words
    }
}

//
//  MAC.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 03/09/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

private typealias CryptoSwift_HMAC = HMAC

/**
 *  Message Authentication
 */
public enum Authenticator {
    
    public enum Error: ErrorType {
        case AuthenticateError
    }
    
    case HMAC(key: [UInt8], variant: CryptoSwift_HMAC.Variant)
    
    /**
     Generates an authenticator for message using a one-time key and returns the 16-byte result
     
     - returns: 16-byte message authentication code
     */
    public func authenticate(message: [UInt8]) throws -> [UInt8] {
        switch (self) {
        case .HMAC(let key, let variant):
            guard let auth = CryptoSwift_HMAC(key: key, variant: variant)?.authenticate(message) else {
                throw Error.AuthenticateError
            }
            return auth
        }
    }
}//
//  Bit.swift
//  CryptoSwift
//
//  Created by Pedro Silva on 29/03/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

enum Bit: Int {
    case Zero
    case One
}

extension Bit {
    func inverted() -> Bit {
        return self == .Zero ? .One : .Zero
    }
}

//
//  BytesSequence.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 26/09/15.
//  Copyright © 2015 Marcin Krzyzanowski. All rights reserved.
//

struct BytesSequence: SequenceType {
    let chunkSize: Int
    let data: [UInt8]
    
    func generate() -> AnyGenerator<ArraySlice<UInt8>> {
        
        var offset:Int = 0
        
        return AnyGenerator {
            let end = min(self.chunkSize, self.data.count - offset)
            let result = self.data[offset..<offset + end]
            offset += result.count
            return result.count > 0 ? result : nil
        }
    }
}

//
//  _ArrayType+Extensions.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 08/10/15.
//  Copyright © 2015 Marcin Krzyzanowski. All rights reserved.
//

public protocol CSArrayType: _ArrayType {
    func cs_arrayValue() -> [Generator.Element]
}

extension Array: CSArrayType {
    public func cs_arrayValue() -> [Generator.Element] {
        return self
    }
}

public extension CSArrayType where Generator.Element == UInt8 {
    public func toHexString() -> String {
        return self.lazy.reduce("") { $0 + String(format:"%02x", $1) }
    }
    
    public func toBase64() -> String? {
        guard let bytesArray = self as? [UInt8] else {
            return nil
        }
        
        return NSData(bytes: bytesArray).base64EncodedStringWithOptions([])
    }
    
    public init(base64: String) {
        self.init()
        
        guard let decodedData = NSData(base64EncodedString: base64, options: []) else {
            return
        }
        
        self.appendContentsOf(decodedData.arrayOfBytes())
    }
}

public extension CSArrayType where Generator.Element == UInt8 {
    
    public func sha256() -> [Generator.Element] {
        return Hash.sha256(cs_arrayValue()).calculate()
    }
    
    public func sha512() -> [Generator.Element] {
        return Hash.sha512(cs_arrayValue()).calculate()
    }
    
    public func authenticate(authenticator: Authenticator) throws -> [Generator.Element] {
        return try authenticator.authenticate(cs_arrayValue())
    }
}//
//  Array+Foundation.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 27/09/15.
//  Copyright © 2015 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension Array where Element: _UInt8Type {
    public init(_ data: NSData) {
        self = Array<Element>(count: data.length, repeatedValue: Element.Zero())
        data.getBytes(&self, length: self.count)
    }
}
//
//  PGPDataExtension.swift
//  SwiftPGP
//
//  Created by Marcin Krzyzanowski on 05/07/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

extension NSMutableData {
    
    /** Convenient way to append bytes */
    internal func appendBytes(arrayOfBytes: [UInt8]) {
        self.appendBytes(arrayOfBytes, length: arrayOfBytes.count)
    }
    
}

extension NSData {
    
    /// Two octet checksum as defined in RFC-4880. Sum of all octets, mod 65536
    public func checksum() -> UInt16 {
        var s:UInt32 = 0
        var bytesArray = self.arrayOfBytes()
        for i in 0..<bytesArray.count {
            s = s + UInt32(bytesArray[i])
        }
        s = s % 65536
        return UInt16(s)
    }
    
    public func sha256() -> NSData? {
        let result = Hash.sha256(self.arrayOfBytes()).calculate()
        return NSData.withBytes(result)
    }
    
    public func sha512() -> NSData? {
        let result = Hash.sha512(self.arrayOfBytes()).calculate()
        return NSData.withBytes(result)
    }
    
    public func authenticate(authenticator: Authenticator) throws -> NSData {
        let result = try authenticator.authenticate(self.arrayOfBytes())
        return NSData.withBytes(result)
    }
}

extension NSData {
    
    public func toHexString() -> String {
        return self.arrayOfBytes().toHexString()
    }
    
    public func arrayOfBytes() -> [UInt8] {
        let count = self.length / sizeof(UInt8)
        var bytesArray = [UInt8](count: count, repeatedValue: 0)
        self.getBytes(&bytesArray, length:count * sizeof(UInt8))
        return bytesArray
    }
    
    public convenience init(bytes: [UInt8]) {
        self.init(data: NSData.withBytes(bytes))
    }
    
    class public func withBytes(bytes: [UInt8]) -> NSData {
        return NSData(bytes: bytes, length: bytes.count)
    }
}

//
//  String+LinuxFoundation.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 27/12/15.
//  Copyright © 2015 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

// Workaround:
// https://github.com/krzyzanowskim/CryptoSwift/issues/177
extension String {
    #if !os(Linux)
    func bridge() -> NSString {
        return self as NSString
    }
    #endif
}

//
//  Generics.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 02/09/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

/** Protocol and extensions for integerFromBitsArray. Bit hakish for me, but I can't do it in any other way */
protocol Initiable  {
    init(_ v: Int)
    init(_ v: UInt)
}

extension Int:Initiable {}
extension UInt:Initiable {}
extension UInt8:Initiable {}
extension UInt16:Initiable {}
extension UInt32:Initiable {}
extension UInt64:Initiable {}

/** build bit pattern from array of bits */
func integerFromBitsArray<T: UnsignedIntegerType>(bits: [Bit]) -> T
{
    var bitPattern:T = 0
    for (idx,b) in bits.enumerate() {
        if (b == Bit.One) {
            let bit = T(UIntMax(1) << UIntMax(idx))
            bitPattern = bitPattern | bit
        }
    }
    return bitPattern
}

/// Initialize integer from array of bytes.
/// This method may be slow
func integerWithBytes<T: IntegerType where T:ByteConvertible, T: BitshiftOperationsType>(bytes: [UInt8]) -> T {
    var bytes = bytes.reverse() as Array<UInt8> //FIXME: check it this is equivalent of Array(...)
    if bytes.count < sizeof(T) {
        let paddingCount = sizeof(T) - bytes.count
        if (paddingCount > 0) {
            bytes += [UInt8](count: paddingCount, repeatedValue: 0)
        }
    }
    
    if sizeof(T) == 1 {
        return T(truncatingBitPattern: UInt64(bytes.first!))
    }
    
    var result: T = 0
    for byte in bytes.reverse() {
        result = result << 8 | T(byte)
    }
    return result
}

/// Array of bytes, little-endian representation. Don't use if not necessary.
/// I found this method slow
func arrayOfBytes<T>(value:T, length:Int? = nil) -> [UInt8] {
    let totalBytes = length ?? sizeof(T)
    
    let valuePointer = UnsafeMutablePointer<T>.alloc(1)
    valuePointer.memory = value
    
    let bytesPointer = UnsafeMutablePointer<UInt8>(valuePointer)
    var bytes = [UInt8](count: totalBytes, repeatedValue: 0)
    for j in 0..<min(sizeof(T),totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).memory
    }
    
    valuePointer.destroy()
    valuePointer.dealloc(1)
    
    return bytes
}

// MARK: - shiftLeft

// helper to be able tomake shift operation on T
func << <T:SignedIntegerType>(lhs: T, rhs: Int) -> Int {
    let a = lhs as! Int
    let b = rhs
    return a << b
}

func << <T:UnsignedIntegerType>(lhs: T, rhs: Int) -> UInt {
    let a = lhs as! UInt
    let b = rhs
    return a << b
}

// Generic function itself
// FIXME: this generic function is not as generic as I would. It crashes for smaller types
func shiftLeft<T: SignedIntegerType where T: Initiable>(value: T, count: Int) -> T {
    if (value == 0) {
        return 0;
    }
    
    let bitsCount = (sizeofValue(value) * 8)
    let shiftCount = Int(Swift.min(count, bitsCount - 1))
    
    var shiftedValue:T = 0;
    for bitIdx in 0..<bitsCount {
        let bit = T(IntMax(1 << bitIdx))
        if ((value & bit) == bit) {
            shiftedValue = shiftedValue | T(bit << shiftCount)
        }
    }
    
    if (shiftedValue != 0 && count >= bitsCount) {
        // clear last bit that couldn't be shifted out of range
        shiftedValue = shiftedValue & T(~(1 << (bitsCount - 1)))
    }
    return shiftedValue
}

// for any f*** other Integer type - this part is so non-Generic
func shiftLeft(value: UInt, count: Int) -> UInt {
    return UInt(shiftLeft(Int(value), count: count)) //FIXME: count:
}

func shiftLeft(value: UInt8, count: Int) -> UInt8 {
    return UInt8(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: UInt16, count: Int) -> UInt16 {
    return UInt16(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: UInt32, count: Int) -> UInt32 {
    return UInt32(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: UInt64, count: Int) -> UInt64 {
    return UInt64(shiftLeft(UInt(value), count: count))
}

func shiftLeft(value: Int8, count: Int) -> Int8 {
    return Int8(shiftLeft(Int(value), count: count))
}

func shiftLeft(value: Int16, count: Int) -> Int16 {
    return Int16(shiftLeft(Int(value), count: count))
}

func shiftLeft(value: Int32, count: Int) -> Int32 {
    return Int32(shiftLeft(Int(value), count: count))
}

func shiftLeft(value: Int64, count: Int) -> Int64 {
    return Int64(shiftLeft(Int(value), count: count))
}

//
//  CryptoHash.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 07/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

public enum Hash {
    case sha256(Array<UInt8>), sha512(Array<UInt8>)
    
    public func calculate() -> [UInt8] {
        switch self {
        case sha256(let bytes):
            return SHA2(bytes, variant: .sha256).calculate32()
        case sha512(let bytes):
            return SHA2(bytes, variant: .sha512).calculate64()
        }
    }
}//
//  HashProtocol.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 17/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

internal protocol HashProtocol {
    var message: Array<UInt8> { get }
    
    /** Common part for hash calculation. Prepare header data. */
    func prepare(len:Int) -> Array<UInt8>
}

extension HashProtocol {
    
    func prepare(len:Int) -> Array<UInt8> {
        var tmpMessage = message
        
        // Step 1. Append Padding Bits
        tmpMessage.append(0x80) // append one bit (UInt8 with one bit) to message
        
        // append "0" bit until message length in bits ≡ 448 (mod 512)
        var msgLength = tmpMessage.count
        var counter = 0
        
        while msgLength % len != (len - 8) {
            counter += 1
            msgLength += 1
        }
        
        tmpMessage += Array<UInt8>(count: counter, repeatedValue: 0)
        return tmpMessage
    }
}//
//  HMAC.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 13/01/15.
//  Copyright (c) 2015 Marcin Krzyzanowski. All rights reserved.
//

final public class HMAC {
    
    public enum Variant {
        case sha256, sha512
        
        var size:Int {
            switch (self) {
            case .sha256:
                return SHA2.Variant.sha256.size
            case .sha512:
                return SHA2.Variant.sha512.size
            }
        }
        
        func calculateHash(bytes bytes:[UInt8]) -> [UInt8]? {
            switch (self) {
            case .sha256:
                return Hash.sha256(bytes).calculate()
            case .sha512:
                return Hash.sha512(bytes).calculate()
            }
        }
        
        func blockSize() -> Int {
            switch self {
            case .sha256:
                return 64
            case .sha512:
                return 128
            }
        }
    }
    
    var key:[UInt8]
    let variant:Variant
    
    public init? (key: [UInt8], variant:HMAC.Variant = .sha256) {
        self.variant = variant
        self.key = key
        
        if (key.count > variant.blockSize()) {
            if let hash = variant.calculateHash(bytes: key) {
                self.key = hash
            }
        }
        
        if (key.count < variant.blockSize()) { // keys shorter than blocksize are zero-padded
            self.key = key + [UInt8](count: variant.blockSize() - key.count, repeatedValue: 0)
        }
    }
    
    public func authenticate(message:[UInt8]) -> [UInt8]? {
        var opad = [UInt8](count: variant.blockSize(), repeatedValue: 0x5c)
        for (idx, _) in key.enumerate() {
            opad[idx] = key[idx] ^ opad[idx]
        }
        var ipad = [UInt8](count: variant.blockSize(), repeatedValue: 0x36)
        for (idx, _) in key.enumerate() {
            ipad[idx] = key[idx] ^ ipad[idx]
        }
        
        var finalHash:[UInt8]? = nil;
        if let ipadAndMessageHash = variant.calculateHash(bytes: ipad + message) {
            finalHash = variant.calculateHash(bytes: opad + ipadAndMessageHash);
        }
        return finalHash
    }
}//
//  IntegerConvertible.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 02/06/15.
//  Copyright (c) 2015 Marcin Krzyzanowski. All rights reserved.
//

protocol BitshiftOperationsType {
    func <<(lhs: Self, rhs: Self) -> Self
    func >>(lhs: Self, rhs: Self) -> Self
    func <<=(inout lhs: Self, rhs: Self)
    func >>=(inout lhs: Self, rhs: Self)
}

protocol ByteConvertible {
    init(_ value: UInt8)
    init(truncatingBitPattern: UInt64)
}

extension Int    : BitshiftOperationsType, ByteConvertible { }
extension Int8   : BitshiftOperationsType, ByteConvertible { }
extension Int16  : BitshiftOperationsType, ByteConvertible { }
extension Int32  : BitshiftOperationsType, ByteConvertible { }
extension Int64  : BitshiftOperationsType, ByteConvertible {
    init(truncatingBitPattern value: UInt64) {
        self = Int64(bitPattern: value)
    }
}
extension UInt   : BitshiftOperationsType, ByteConvertible { }
extension UInt8  : BitshiftOperationsType, ByteConvertible { }
extension UInt16 : BitshiftOperationsType, ByteConvertible { }
extension UInt32 : BitshiftOperationsType, ByteConvertible { }
extension UInt64 : BitshiftOperationsType, ByteConvertible {
    init(truncatingBitPattern value: UInt64) {
        self = value
    }
}//
//  IntExtension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 12/08/14.
//  Copyright (C) 2014 Marcin Krzyżanowski <marcin.krzyzanowski@gmail.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif


/* array of bits */
extension Int {
    init(bits: [Bit]) {
        self.init(bitPattern: integerFromBitsArray(bits) as UInt)
    }
}

/* array of bytes */
extension Int {
    /** Array of bytes with optional padding (little-endian) */
    public func bytes(totalBytes: Int = sizeof(Int)) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
    
    public static func withBytes(bytes: ArraySlice<UInt8>) -> Int {
        return Int.withBytes(Array(bytes))
    }
    
    /** Int with array bytes (little-endian) */
    public static func withBytes(bytes: [UInt8]) -> Int {
        return integerWithBytes(bytes)
    }
}



/** Shift bits */
extension Int {
    
    /** Shift bits to the left. All bits are shifted (including sign bit) */
    private mutating func shiftLeft(count: Int) -> Int {
        self = CryptoSwift_shiftLeft(self, count: count) //FIXME: count:
        return self
    }
    
    /** Shift bits to the right. All bits are shifted (including sign bit) */
    private mutating func shiftRight(count: Int) -> Int {
        if (self == 0) {
            return self;
        }
        
        let bitsCount = sizeofValue(self) * 8
        
        if (count >= bitsCount) {
            return 0
        }
        
        let maxBitsForValue = Int(floor(log2(Double(self)) + 1))
        let shiftCount = Swift.min(count, maxBitsForValue - 1)
        var shiftedValue:Int = 0;
        
        for bitIdx in 0..<bitsCount {
            // if bit is set then copy to result and shift left 1
            let bit = 1 << bitIdx
            if ((self & bit) == bit) {
                shiftedValue = shiftedValue | (bit >> shiftCount)
            }
        }
        self = Int(shiftedValue)
        return self
    }
}

func CryptoSwift_shiftLeft(value: Int, count: Int) -> Int {
    return shiftLeft(value, count: count)
}

// Left operator

/** shift left and assign with bits truncation */
public func &<<= (inout lhs: Int, rhs: Int) {
    lhs.shiftLeft(rhs)
}

/** shift left with bits truncation */
public func &<< (lhs: Int, rhs: Int) -> Int {
    var l = lhs;
    l.shiftLeft(rhs)
    return l
}

// Right operator

/** shift right and assign with bits truncation */
func &>>= (inout lhs: Int, rhs: Int) {
    lhs.shiftRight(rhs)
}

/** shift right and assign with bits truncation */
func &>> (lhs: Int, rhs: Int) -> Int {
    var l = lhs;
    l.shiftRight(rhs)
    return l
}

//
//  Multiplatform.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 03/12/15.
//  Copyright © 2015 Marcin Krzyzanowski. All rights reserved.
//

#if os(Linux)
    import Glibc
    import SwiftShims
#else
    import Darwin
#endif

func cs_arc4random_uniform(upperBound: UInt32) -> UInt32 {
    #if os(Linux)
        return _swift_stdlib_arc4random_uniform(upperBound)
    #else
        return arc4random_uniform(upperBound)
    #endif
}
//
//  Operators.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 02/09/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//
/*
 Bit shifting with overflow protection using overflow operator "&".
 Approach is consistent with standard overflow operators &+, &-, &*, &/
 and introduce new overflow operators for shifting: &<<, &>>
 
 Note: Works with unsigned integers values only
 
 Usage
 
 var i = 1       // init
 var j = i &<< 2 //shift left
 j &<<= 2        //shift left and assign
 
 
 @see: https://medium.com/@krzyzanowskim/swiftly-shift-bits-and-protect-yourself-be33016ce071
 */

infix operator &<<= {
associativity none
precedence 160
}

infix operator &<< {
associativity none
precedence 160
}

infix operator &>>= {
associativity none
precedence 160
}

infix operator &>> {
associativity none
precedence 160
}

//
//  SHA2.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 24/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

final class SHA2 : HashProtocol {
    var size:Int { return variant.rawValue }
    let variant:SHA2.Variant
    
    let message: [UInt8]
    
    init(_ message:[UInt8], variant: SHA2.Variant) {
        self.variant = variant
        self.message = message
    }
    
    enum Variant: RawRepresentable {
        case sha256, sha512
        
        typealias RawValue = Int
        var rawValue: RawValue {
            switch (self) {
            case .sha256:
                return 256
            case .sha512:
                return 512
            }
        }
        
        init?(rawValue: RawValue) {
            switch (rawValue) {
            case 256:
                self = .sha256
                break;
            case 512:
                self = .sha512
                break;
            default:
                return nil
            }
        }
        
        var size:Int { return self.rawValue }
        
        private var h:[UInt64] {
            switch (self) {
            case .sha256:
                return [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
            case .sha512:
                return [0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1, 0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179]
            }
        }
        
        private var k:[UInt64] {
            switch (self) {
            case .sha256:
                return [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
                        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
                        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
                        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
                        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
                        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
                        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2]
            case .sha512:
                return [0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538,
                        0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe,
                        0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
                        0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
                        0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab,
                        0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
                        0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed,
                        0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
                        0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
                        0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53,
                        0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373,
                        0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
                        0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c,
                        0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6,
                        0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
                        0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817]
            }
        }
        
        private func resultingArray<T>(hh:[T]) -> ArraySlice<T> {
            switch (self) {
            default:
                break;
            }
            return ArraySlice(hh)
        }
    }
    
    //FIXME: I can't do Generic func out of calculate32 and calculate64 (UInt32 vs UInt64), but if you can - please do pull request.
    func calculate32() -> [UInt8] {
        var tmpMessage = self.prepare(64)
        
        // hash values
        var hh = [UInt32]()
        variant.h.forEach {(h) -> () in
            hh.append(UInt32(h))
        }
        
        // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
        tmpMessage += (message.count * 8).bytes(64 / 8)
        
        // Process the message in successive 512-bit chunks:
        let chunkSizeBytes = 512 / 8 // 64
        for chunk in BytesSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
            // Extend the sixteen 32-bit words into sixty-four 32-bit words:
            var M:[UInt32] = [UInt32](count: variant.k.count, repeatedValue: 0)
            for x in 0..<M.count {
                switch (x) {
                case 0...15:
                    let start = chunk.startIndex + (x * sizeofValue(M[x]))
                    let end = start + sizeofValue(M[x])
                    let le = toUInt32Array(chunk[start..<end])[0]
                    M[x] = le.bigEndian
                    break
                default:
                    let s0 = rotateRight(M[x-15], n: 7) ^ rotateRight(M[x-15], n: 18) ^ (M[x-15] >> 3) //FIXME: n
                    let s1 = rotateRight(M[x-2], n: 17) ^ rotateRight(M[x-2], n: 19) ^ (M[x-2] >> 10)
                    M[x] = M[x-16] &+ s0 &+ M[x-7] &+ s1
                    break
                }
            }
            
            var A = hh[0]
            var B = hh[1]
            var C = hh[2]
            var D = hh[3]
            var E = hh[4]
            var F = hh[5]
            var G = hh[6]
            var H = hh[7]
            
            // Main loop
            for j in 0..<variant.k.count {
                let s0 = rotateRight(A,n: 2) ^ rotateRight(A,n: 13) ^ rotateRight(A,n: 22)
                let maj = (A & B) ^ (A & C) ^ (B & C)
                let t2 = s0 &+ maj
                let s1 = rotateRight(E,n: 6) ^ rotateRight(E,n: 11) ^ rotateRight(E,n: 25)
                let ch = (E & F) ^ ((~E) & G)
                let t1 = H &+ s1 &+ ch &+ UInt32(variant.k[j]) &+ M[j]
                
                H = G
                G = F
                F = E
                E = D &+ t1
                D = C
                C = B
                B = A
                A = t1 &+ t2
            }
            
            hh[0] = (hh[0] &+ A)
            hh[1] = (hh[1] &+ B)
            hh[2] = (hh[2] &+ C)
            hh[3] = (hh[3] &+ D)
            hh[4] = (hh[4] &+ E)
            hh[5] = (hh[5] &+ F)
            hh[6] = (hh[6] &+ G)
            hh[7] = (hh[7] &+ H)
        }
        
        // Produce the final hash value (big-endian) as a 160 bit number:
        var result = [UInt8]()
        result.reserveCapacity(hh.count / 4)
        variant.resultingArray(hh).forEach {
            let item = $0.bigEndian
            result += [UInt8(item & 0xff), UInt8((item >> 8) & 0xff), UInt8((item >> 16) & 0xff), UInt8((item >> 24) & 0xff)]
        }
        return result
    }
    
    func calculate64() -> [UInt8] {
        var tmpMessage = self.prepare(128)
        
        // hash values
        var hh = [UInt64]()
        variant.h.forEach {(h) -> () in
            hh.append(h)
        }
        
        
        // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
        tmpMessage += (message.count * 8).bytes(64 / 8)
        
        // Process the message in successive 1024-bit chunks:
        let chunkSizeBytes = 1024 / 8 // 128
        for chunk in BytesSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
            // break chunk into sixteen 64-bit words M[j], 0 ≤ j ≤ 15, big-endian
            // Extend the sixteen 64-bit words into eighty 64-bit words:
            var M = [UInt64](count: variant.k.count, repeatedValue: 0)
            for x in 0..<M.count {
                switch (x) {
                case 0...15:
                    let start = chunk.startIndex + (x * sizeofValue(M[x]))
                    let end = start + sizeofValue(M[x])
                    let le = toUInt64Array(chunk[start..<end])[0]
                    M[x] = le.bigEndian
                    break
                default:
                    let s0 = rotateRight(M[x-15], n: 1) ^ rotateRight(M[x-15], n: 8) ^ (M[x-15] >> 7)
                    let s1 = rotateRight(M[x-2], n: 19) ^ rotateRight(M[x-2], n: 61) ^ (M[x-2] >> 6)
                    M[x] = M[x-16] &+ s0 &+ M[x-7] &+ s1
                    break
                }
            }
            
            var A = hh[0]
            var B = hh[1]
            var C = hh[2]
            var D = hh[3]
            var E = hh[4]
            var F = hh[5]
            var G = hh[6]
            var H = hh[7]
            
            // Main loop
            for j in 0..<variant.k.count {
                let s0 = rotateRight(A,n: 28) ^ rotateRight(A,n: 34) ^ rotateRight(A,n: 39) //FIXME: n:
                let maj = (A & B) ^ (A & C) ^ (B & C)
                let t2 = s0 &+ maj
                let s1 = rotateRight(E,n: 14) ^ rotateRight(E,n: 18) ^ rotateRight(E,n: 41)
                let ch = (E & F) ^ ((~E) & G)
                let t1 = H &+ s1 &+ ch &+ variant.k[j] &+ UInt64(M[j])
                
                H = G
                G = F
                F = E
                E = D &+ t1
                D = C
                C = B
                B = A
                A = t1 &+ t2
            }
            
            hh[0] = (hh[0] &+ A)
            hh[1] = (hh[1] &+ B)
            hh[2] = (hh[2] &+ C)
            hh[3] = (hh[3] &+ D)
            hh[4] = (hh[4] &+ E)
            hh[5] = (hh[5] &+ F)
            hh[6] = (hh[6] &+ G)
            hh[7] = (hh[7] &+ H)
        }
        
        // Produce the final hash value (big-endian)
        var result = [UInt8]()
        result.reserveCapacity(hh.count / 4)
        variant.resultingArray(hh).forEach {
            let item = $0.bigEndian
            var partialResult = [UInt8]()
            partialResult.reserveCapacity(8)
            for i in 0..<8 {
                let shift = UInt64(8 * i)
                partialResult.append(UInt8((item >> shift) & 0xff))
            }
            result += partialResult
        }
        return result
    }
}//
//  StringExtension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 15/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

/** String extension */
extension String {
    
    public func sha256() -> String {
        return self.utf8.lazy.map({ $0 as UInt8 }).sha256().toHexString()
    }
    
    public func sha512() -> String {
        return self.utf8.lazy.map({ $0 as UInt8 }).sha512().toHexString()
    }
    
    /// Returns hex string of bytes.
    public func authenticate(authenticator: Authenticator) throws -> String {
        return  try self.utf8.lazy.map({ $0 as UInt8 }).authenticate(authenticator).toHexString()
    }
}//
//  UInt32Extension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 02/09/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif


protocol _UInt32Type { }
extension UInt32: _UInt32Type {}

/** array of bytes */
extension UInt32 {
    public func bytes(totalBytes: Int = sizeof(UInt32)) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
    
    public static func withBytes(bytes: ArraySlice<UInt8>) -> UInt32 {
        return UInt32.withBytes(Array(bytes))
    }
    
    /** Int with array bytes (little-endian) */
    public static func withBytes(bytes: [UInt8]) -> UInt32 {
        return integerWithBytes(bytes)
    }
}

/** Shift bits */
extension UInt32 {
    
    /** Shift bits to the left. All bits are shifted (including sign bit) */
    private mutating func shiftLeft(count: UInt32) -> UInt32 {
        if (self == 0) {
            return self;
        }
        
        let bitsCount = UInt32(sizeof(UInt32) * 8)
        let shiftCount = Swift.min(count, bitsCount - 1)
        var shiftedValue:UInt32 = 0;
        
        for bitIdx in 0..<bitsCount {
            // if bit is set then copy to result and shift left 1
            let bit = 1 << bitIdx
            if ((self & bit) == bit) {
                shiftedValue = shiftedValue | (bit << shiftCount)
            }
        }
        
        if (shiftedValue != 0 && count >= bitsCount) {
            // clear last bit that couldn't be shifted out of range
            shiftedValue = shiftedValue & (~(1 << (bitsCount - 1)))
        }
        
        self = shiftedValue
        return self
    }
    
    /** Shift bits to the right. All bits are shifted (including sign bit) */
    private mutating func shiftRight(count: UInt32) -> UInt32 {
        if (self == 0) {
            return self;
        }
        
        let bitsCount = UInt32(sizeofValue(self) * 8)
        
        if (count >= bitsCount) {
            return 0
        }
        
        let maxBitsForValue = UInt32(floor(log2(Double(self)) + 1))
        let shiftCount = Swift.min(count, maxBitsForValue - 1)
        var shiftedValue:UInt32 = 0;
        
        for bitIdx in 0..<bitsCount {
            // if bit is set then copy to result and shift left 1
            let bit = 1 << bitIdx
            if ((self & bit) == bit) {
                shiftedValue = shiftedValue | (bit >> shiftCount)
            }
        }
        self = shiftedValue
        return self
    }
    
}

/** shift left and assign with bits truncation */
public func &<<= (inout lhs: UInt32, rhs: UInt32) {
    lhs.shiftLeft(rhs)
}

/** shift left with bits truncation */
public func &<< (lhs: UInt32, rhs: UInt32) -> UInt32 {
    var l = lhs;
    l.shiftLeft(rhs)
    return l
}

/** shift right and assign with bits truncation */
func &>>= (inout lhs: UInt32, rhs: UInt32) {
    lhs.shiftRight(rhs)
}

/** shift right and assign with bits truncation */
func &>> (lhs: UInt32, rhs: UInt32) -> UInt32 {
    var l = lhs;
    l.shiftRight(rhs)
    return l
}//
//  UInt64Extension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 02/09/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

/** array of bytes */
extension UInt64 {
    public func bytes(totalBytes: Int = sizeof(UInt64)) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
    
    public static func withBytes(bytes: ArraySlice<UInt8>) -> UInt64 {
        return UInt64.withBytes(Array(bytes))
    }
    
    /** Int with array bytes (little-endian) */
    public static func withBytes(bytes: [UInt8]) -> UInt64 {
        return integerWithBytes(bytes)
    }
}//
//  ByteExtension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 07/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif


public protocol _UInt8Type { }
extension UInt8: _UInt8Type {}

extension _UInt8Type {
    static func Zero() -> Self {
        return 0 as! Self
    }
}


/** casting */
extension UInt8 {
    
    /** cast because UInt8(<UInt32>) because std initializer crash if value is > byte */
    static func withValue(v:UInt64) -> UInt8 {
        let tmp = v & 0xFF
        return UInt8(tmp)
    }
    
    static func withValue(v:UInt32) -> UInt8 {
        let tmp = v & 0xFF
        return UInt8(tmp)
    }
    
    static func withValue(v:UInt16) -> UInt8 {
        let tmp = v & 0xFF
        return UInt8(tmp)
    }
    
}

/** Bits */
extension UInt8 {
    
    init(bits: [Bit]) {
        self.init(integerFromBitsArray(bits) as UInt8)
    }
    
    /** array of bits */
    func bits() -> [Bit] {
        let totalBitsCount = sizeofValue(self) * 8
        
        var bitsArray = [Bit](count: totalBitsCount, repeatedValue: Bit.Zero)
        
        for j in 0..<totalBitsCount {
            let bitVal:UInt8 = 1 << UInt8(totalBitsCount - 1 - j)
            let check = self & bitVal
            
            if (check != 0) {
                bitsArray[j] = Bit.One;
            }
        }
        return bitsArray
    }
    
    func bits() -> String {
        var s = String()
        let arr:[Bit] = self.bits()
        for (idx,b) in arr.enumerate() {
            s += (b == Bit.One ? "1" : "0")
            if ((idx + 1) % 8 == 0) { s += " " }
        }
        return s
    }
}

/** Shift bits */
extension UInt8 {
    /** Shift bits to the right. All bits are shifted (including sign bit) */
    mutating func shiftRight(count: UInt8) -> UInt8 {
        if (self == 0) {
            return self;
        }
        
        let bitsCount = UInt8(sizeof(UInt8) * 8)
        
        if (count >= bitsCount) {
            return 0
        }
        
        let maxBitsForValue = UInt8(floor(log2(Double(self) + 1)))
        let shiftCount = Swift.min(count, maxBitsForValue - 1)
        var shiftedValue:UInt8 = 0;
        
        for bitIdx in 0..<bitsCount {
            let byte = 1 << bitIdx
            if ((self & byte) == byte) {
                shiftedValue = shiftedValue | (byte >> shiftCount)
            }
        }
        self = shiftedValue
        return self
    }
}

/** shift right and assign with bits truncation */
func &>> (lhs: UInt8, rhs: UInt8) -> UInt8 {
    var l = lhs;
    l.shiftRight(rhs)
    return l
}//
//  Utils.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 26/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

func rotateRight(x:UInt16, n:UInt16) -> UInt16 {
    return (x >> n) | (x << (16 - n))
}

func rotateRight(x:UInt32, n:UInt32) -> UInt32 {
    return (x >> n) | (x << (32 - n))
}

func rotateRight(x:UInt64, n:UInt64) -> UInt64 {
    return ((x >> n) | (x << (64 - n)))
}

func toUInt32Array(slice: ArraySlice<UInt8>) -> Array<UInt32> {
    var result = Array<UInt32>()
    result.reserveCapacity(16)
    
    for idx in slice.startIndex.stride(to: slice.endIndex, by: sizeof(UInt32)) {
        let val1:UInt32 = (UInt32(slice[idx.advancedBy(3)]) << 24)
        let val2:UInt32 = (UInt32(slice[idx.advancedBy(2)]) << 16)
        let val3:UInt32 = (UInt32(slice[idx.advancedBy(1)]) << 8)
        let val4:UInt32 = UInt32(slice[idx])
        let val:UInt32 = val1 | val2 | val3 | val4
        result.append(val)
    }
    return result
}

func toUInt64Array(slice: ArraySlice<UInt8>) -> Array<UInt64> {
    var result = Array<UInt64>()
    result.reserveCapacity(32)
    for idx in slice.startIndex.stride(to: slice.endIndex, by: sizeof(UInt64)) {
        var val:UInt64 = 0
        val |= UInt64(slice[idx.advancedBy(7)]) << 56
        val |= UInt64(slice[idx.advancedBy(6)]) << 48
        val |= UInt64(slice[idx.advancedBy(5)]) << 40
        val |= UInt64(slice[idx.advancedBy(4)]) << 32
        val |= UInt64(slice[idx.advancedBy(3)]) << 24
        val |= UInt64(slice[idx.advancedBy(2)]) << 16
        val |= UInt64(slice[idx.advancedBy(1)]) << 8
        val |= UInt64(slice[idx.advancedBy(0)]) << 0
        result.append(val)
    }
    return result
}
