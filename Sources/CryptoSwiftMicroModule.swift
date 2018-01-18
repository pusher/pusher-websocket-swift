// This is based on https://github.com/krzyzanowskim/CryptoSwift with modifications
// specific to the use case of PusherSwift. Based on SHA 1d50d433e6.
//
// File created by:
//
// * Delete these files:
//   - Sources/CryptoSwift/AES.Cryptors.swift
//   - Sources/CryptoSwift/AES.swift
//   - Sources/CryptoSwift/BlockCipher.swift
//   - Sources/CryptoSwift/BlockMode/BlockMode.swift
//   - Sources/CryptoSwift/BlockMode/BlockModeOptions.swift
//   - Sources/CryptoSwift/BlockMode/BlockModeWorker.swift
//   - Sources/CryptoSwift/BlockMode/CBC.swift
//   - Sources/CryptoSwift/BlockMode/CFB.swift
//   - Sources/CryptoSwift/BlockMode/CTR.swift
//   - Sources/CryptoSwift/BlockMode/ECB.swift
//   - Sources/CryptoSwift/BlockMode/OFB.swift
//   - Sources/CryptoSwift/BlockMode/PCBC.swift
//   - Sources/CryptoSwift/BlockMode/RandomAccessBlockModeWorker.swift
//   - Sources/CryptoSwift/Blowfish.swift
//   - Sources/CryptoSwift/ChaCha20.swift
//   - Sources/CryptoSwift/Checksum.swift
//   - Sources/CryptoSwift/Cipher.swift
//   - Sources/CryptoSwift/Cryptors.swift
//   - Sources/CryptoSwift/Foundation/AES+Foundation.swift
//   - Sources/CryptoSwift/Foundation/Blowfish+Foundation.swift
//   - Sources/CryptoSwift/Foundation/ChaCha20+Foundation.swift
//   - Sources/CryptoSwift/Foundation/Rabbit+Foundation.swift
//   - Sources/CryptoSwift/Foundation/String+FoundationExtension.swift
//   - Sources/CryptoSwift/Foundation/Utils+Foundation.swift
//   - Sources/CryptoSwift/HKDF.swift
//   - Sources/CryptoSwift/Operators.swift
//   - Sources/CryptoSwift/PKCS/PBKDF1.swift
//   - Sources/CryptoSwift/PKCS/PBKDF2.swift
//   - Sources/CryptoSwift/PKCS/PKCS5.swift
//   - Sources/CryptoSwift/PKCS/PKCS7.swift
//   - Sources/CryptoSwift/PKCS/PKCS7Padding.swift
//   - Sources/CryptoSwift/Poly1305.swift
//   - Sources/CryptoSwift/Rabbit.swift
//   - Sources/CryptoSwift/RandomAccessCryptor.swift
//   - Sources/CryptoSwift/RandomBytesSequence.swift
//   - Sources/CryptoSwift/SHA3.swift
//   - Sources/CryptoSwift/SecureBytes.swift
//
// * Modify these files as appropriate (remove unused SHA-*s, etc)
//    - Sources/CryptoSwift/Array+Extensions.swift
//    - Sources/CryptoSwift/Digest.swift
//    - Sources/CryptoSwift/Foundation/Data+Extension.swift
//    - Sources/CryptoSwift/HMAC.swift
//    - Sources/CryptoSwift/Padding.swift
//    - Sources/CryptoSwift/SHA2.swift
//    - Sources/CryptoSwift/String+Extension.swift
//
// * Run: cat Sources/CryptoSwift/**/*.swift > CryptoSwiftMicroModule.swift
//
// Then made otherwise public API internal so as to avoid collisions. Basically
// just change all `public`s to `internal`s.
//
// ---------------------------------------
//
//  ArrayExtension.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

extension Array {
    init(reserveCapacity: Int) {
        self = Array<Element>()
        self.reserveCapacity(reserveCapacity)
    }

    var slice: ArraySlice<Element> {
        return self[self.startIndex..<self.endIndex]
    }
}

extension Array {

    /// split in chunks with given chunk size
    @available(*, deprecated: 0.8.0, message: "")
    internal func chunks(size chunksize: Int) -> Array<Array<Element>> {
        var words = Array<Array<Element>>()
        words.reserveCapacity(count / chunksize)
        for idx in stride(from: chunksize, through: count, by: chunksize) {
            words.append(Array(self[idx - chunksize..<idx])) // slow for large table
        }
        let remainder = suffix(count % chunksize)
        if !remainder.isEmpty {
            words.append(Array(remainder))
        }
        return words
    }
}

extension Array where Element == UInt8 {

    internal init(hex: String) {
        self.init(reserveCapacity: hex.unicodeScalars.lazy.underestimatedCount)
        var buffer: UInt8?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }
}
//
//  Array+Extensions.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

internal extension Array where Element == UInt8 {

    internal func toHexString() -> String {
        return `lazy`.reduce("") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
}

internal extension Array where Element == UInt8 {

    internal func md5() -> [Element] {
        return Digest.md5(self)
    }

    internal func sha1() -> [Element] {
        return Digest.sha1(self)
    }

    internal func sha256() -> [Element] {
        return Digest.sha256(self)
    }

    internal func sha512() -> [Element] {
        return Digest.sha512(self)
    }

    internal func authenticate<A: Authenticator>(with authenticator: A) throws -> [Element] {
        return try authenticator.authenticate(self)
    }
}
//
//  MAC.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/// Message authentication code.
internal protocol Authenticator {
    /// Calculate Message Authentication Code (MAC) for message.
    func authenticate(_ bytes: Array<UInt8>) throws -> Array<UInt8>
}
//
//  BatchedCollection.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

struct BatchedCollectionIndex<Base: Collection> {
    let range: Range<Base.Index>
}

extension BatchedCollectionIndex: Comparable {
    static func ==<Base>(lhs: BatchedCollectionIndex<Base>, rhs: BatchedCollectionIndex<Base>) -> Bool {
        return lhs.range.lowerBound == rhs.range.lowerBound
    }

    static func < <Base>(lhs: BatchedCollectionIndex<Base>, rhs: BatchedCollectionIndex<Base>) -> Bool {
        return lhs.range.lowerBound < rhs.range.lowerBound
    }
}

protocol BatchedCollectionType: Collection {
    associatedtype Base: Collection
}

struct BatchedCollection<Base: Collection>: Collection {
    let base: Base
    let size: Base.IndexDistance
    typealias Index = BatchedCollectionIndex<Base>
    private func nextBreak(after idx: Base.Index) -> Base.Index {
        return base.index(idx, offsetBy: size, limitedBy: base.endIndex)
            ?? base.endIndex
    }

    var startIndex: Index {
        return Index(range: base.startIndex..<nextBreak(after: base.startIndex))
    }

    var endIndex: Index {
        return Index(range: base.endIndex..<base.endIndex)
    }

    func index(after idx: Index) -> Index {
        return Index(range: idx.range.upperBound..<nextBreak(after: idx.range.upperBound))
    }

    subscript(idx: Index) -> Base.SubSequence {
        return base[idx.range]
    }
}

extension Collection {
    func batched(by size: IndexDistance) -> BatchedCollection<Self> {
        return BatchedCollection(base: self, size: size)
    }
}
//
//  Bit.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

internal enum Bit: Int {
    case zero
    case one
}

extension Bit {

    func inverted() -> Bit {
        return self == .zero ? .one : .zero
    }
}
//
//  Collection+Extension.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//
extension Collection where Self.Element == UInt8, Self.Index == Int {

    // Big endian order
    func toUInt32Array() -> Array<UInt32> {
        if isEmpty {
            return []
        }

        var result = Array<UInt32>(reserveCapacity: 16)
        for idx in stride(from: startIndex, to: endIndex, by: 4) {
            let val = UInt32(bytes: self, fromIndex: idx).bigEndian
            result.append(val)
        }

        return result
    }

    // Big endian order
    func toUInt64Array() -> Array<UInt64> {
        if isEmpty {
            return []
        }

        var result = Array<UInt64>(reserveCapacity: 32)
        for idx in stride(from: startIndex, to: endIndex, by: 8) {
            let val = UInt64(bytes: self, fromIndex: idx).bigEndian
            result.append(val)
        }

        return result
    }
}
//
//  Hash.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

@available(*, deprecated: 0.6.0, renamed: "Digest")
internal typealias Hash = Digest

/// Hash functions to calculate Digest.
internal struct Digest {

    /// Calculate MD5 Digest
    /// - parameter bytes: input message
    /// - returns: Digest bytes
    internal static func md5(_ bytes: Array<UInt8>) -> Array<UInt8> {
        return MD5().calculate(for: bytes)
    }

    /// Calculate SHA1 Digest
    /// - parameter bytes: input message
    /// - returns: Digest bytes
    internal static func sha1(_ bytes: Array<UInt8>) -> Array<UInt8> {
        return SHA1().calculate(for: bytes)
    }

    /// Calculate SHA2-256 Digest
    /// - parameter bytes: input message
    /// - returns: Digest bytes
    internal static func sha256(_ bytes: Array<UInt8>) -> Array<UInt8> {
        return sha2(bytes, variant: .sha256)
    }

    /// Calculate SHA2-512 Digest
    /// - parameter bytes: input message
    /// - returns: Digest bytes
    internal static func sha512(_ bytes: Array<UInt8>) -> Array<UInt8> {
        return sha2(bytes, variant: .sha512)
    }

    /// Calculate SHA2 Digest
    /// - parameter bytes: input message
    /// - parameter variant: SHA-2 variant
    /// - returns: Digest bytes
    internal static func sha2(_ bytes: Array<UInt8>, variant: SHA2.Variant) -> Array<UInt8> {
        return SHA2(variant: variant).calculate(for: bytes)
    }

}
//
//  Digest.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

internal protocol DigestType {
    func calculate(for bytes: Array<UInt8>) -> Array<UInt8>
}
//
//  Array+Foundation.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

import Foundation

internal extension Array where Element == UInt8 {

    internal func toBase64() -> String? {
        return Data(bytes: self).base64EncodedString()
    }

    internal init(base64: String) {
        self.init()

        guard let decodedData = Data(base64Encoded: base64) else {
            return
        }

        append(contentsOf: decodedData.bytes)
    }
}
//
//  PGPDataExtension.swift
//  SwiftPGP
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

import Foundation

extension Data {

    /// Two octet checksum as defined in RFC-4880. Sum of all octets, mod 65536
    internal func checksum() -> UInt16 {
        var s: UInt32 = 0
        var bytesArray = bytes
        for i in 0..<bytesArray.count {
            s = s + UInt32(bytesArray[i])
        }
        s = s % 65536
        return UInt16(s)
    }

    internal func md5() -> Data {
        return Data(bytes: Digest.md5(bytes))
    }

    internal func sha1() -> Data {
        return Data(bytes: Digest.sha1(bytes))
    }

    internal func sha256() -> Data {
        return Data(bytes: Digest.sha256(bytes))
    }

    internal func sha512() -> Data {
        return Data(bytes: Digest.sha512(bytes))
    }

    internal func authenticate(with authenticator: Authenticator) throws -> Data {
        return Data(bytes: try authenticator.authenticate(bytes))
    }
}

extension Data {

    internal init(hex: String) {
        self.init(bytes: Array<UInt8>(hex: hex))
    }

    internal var bytes: Array<UInt8> {
        return Array(self)
    }

    internal func toHexString() -> String {
        return bytes.toHexString()
    }
}
//
//  HMAC+Foundation.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

import Foundation

extension HMAC {

    internal convenience init(key: String, variant: HMAC.Variant = .md5) throws {
        self.init(key: key.bytes, variant: variant)
    }
}
//
//  Generics.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/** build bit pattern from array of bits */
@_specialize(exported: true, where T == UInt8)
func integerFrom<T: FixedWidthInteger>(_ bits: Array<Bit>) -> T {
    var bitPattern: T = 0
    for idx in bits.indices {
        if bits[idx] == Bit.one {
            let bit = T(UInt64(1) << UInt64(idx))
            bitPattern = bitPattern | bit
        }
    }
    return bitPattern
}

/// Array of bytes. Caution: don't use directly because generic is slow.
///
/// - parameter value: integer value
/// - parameter length: length of output array. By default size of value type
///
/// - returns: Array of bytes
@_specialize(exported: true, where T == Int)
@_specialize(exported: true, where T == UInt)
@_specialize(exported: true, where T == UInt8)
@_specialize(exported: true, where T == UInt16)
@_specialize(exported: true, where T == UInt32)
@_specialize(exported: true, where T == UInt64)
func arrayOfBytes<T: FixedWidthInteger>(value: T, length totalBytes: Int = MemoryLayout<T>.size) -> Array<UInt8> {
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value

    let bytesPointer = UnsafeMutablePointer<UInt8>(OpaquePointer(valuePointer))
    var bytes = Array<UInt8>(repeating: 0, count: totalBytes)
    for j in 0..<min(MemoryLayout<T>.size, totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }

    valuePointer.deinitialize()
    valuePointer.deallocate(capacity: 1)

    return bytes
}
//
//  HMAC.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

internal final class HMAC: Authenticator {

    internal enum Error: Swift.Error {
        case authenticateError
        case invalidInput
    }

    internal enum Variant {
        case sha1, sha256, sha512, md5

        var digestLength: Int {
            switch self {
            case .sha1:
                return SHA1.digestLength
            case .sha256:
                return SHA2.Variant.sha256.digestLength
            case .sha512:
                return SHA2.Variant.sha512.digestLength
            case .md5:
                return MD5.digestLength
            }
        }

        func calculateHash(_ bytes: Array<UInt8>) -> Array<UInt8>? {
            switch self {
            case .sha1:
                return Digest.sha1(bytes)
            case .sha256:
                return Digest.sha256(bytes)
            case .sha512:
                return Digest.sha512(bytes)
            case .md5:
                return Digest.md5(bytes)
            }
        }

        func blockSize() -> Int {
            switch self {
            case .md5:
                return MD5.blockSize
            case .sha1, .sha256:
                return 64
            case .sha512:
                return 128
            }
        }
    }

    var key: Array<UInt8>
    let variant: Variant

    internal init(key: Array<UInt8>, variant: HMAC.Variant = .md5) {
        self.variant = variant
        self.key = key

        if key.count > variant.blockSize() {
            if let hash = variant.calculateHash(key) {
                self.key = hash
            }
        }

        if key.count < variant.blockSize() {
            self.key = ZeroPadding().add(to: key, blockSize: variant.blockSize())
        }
    }

    // MARK: Authenticator

    internal func authenticate(_ bytes: Array<UInt8>) throws -> Array<UInt8> {
        var opad = Array<UInt8>(repeating: 0x5c, count: variant.blockSize())
        for idx in key.indices {
            opad[idx] = key[idx] ^ opad[idx]
        }
        var ipad = Array<UInt8>(repeating: 0x36, count: variant.blockSize())
        for idx in key.indices {
            ipad[idx] = key[idx] ^ ipad[idx]
        }

        guard let ipadAndMessageHash = variant.calculateHash(ipad + bytes),
            let result = variant.calculateHash(opad + ipadAndMessageHash) else {
            throw Error.authenticateError
        }

        // return Array(result[0..<10]) // 80 bits
        return result
    }
}
//
//  IntExtension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 12/08/14.
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

#if os(Linux) || os(Android) || os(FreeBSD)
    import Glibc
#else
    import Darwin
#endif

/* array of bits */
extension Int {
    init(bits: [Bit]) {
        self.init(bitPattern: integerFrom(bits) as UInt)
    }
}

extension FixedWidthInteger {
    @_transparent
    func bytes(totalBytes: Int = MemoryLayout<Self>.size) -> Array<UInt8> {
        return arrayOfBytes(value: self, length: totalBytes)
        // TODO: adjust bytes order
        // var value = self
        // return withUnsafeBytes(of: &value, Array.init).reversed()
    }
}
//
//  MD5.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

internal final class MD5: DigestType {
    static let blockSize: Int = 64
    static let digestLength: Int = 16 // 128 / 8
    fileprivate static let hashInitialValue: Array<UInt32> = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]

    fileprivate var accumulated = Array<UInt8>()
    fileprivate var processedBytesTotalCount: Int = 0
    fileprivate var accumulatedHash: Array<UInt32> = MD5.hashInitialValue

    /** specifies the per-round shift amounts */
    private let s: Array<UInt32> = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    ]

    /** binary integer part of the sines of integers (Radians) */
    private let k: Array<UInt32> = [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x2441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x4881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
    ]

    internal init() {
    }

    internal func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        do {
            return try update(withBytes: bytes.slice, isLast: true)
        } catch {
            fatalError()
        }
    }

    // mutating currentHash in place is way faster than returning new result
    fileprivate func process(block chunk: ArraySlice<UInt8>, currentHash: inout Array<UInt32>) {
        assert(chunk.count == 16 * 4)

        // Initialize hash value for this chunk:
        var A: UInt32 = currentHash[0]
        var B: UInt32 = currentHash[1]
        var C: UInt32 = currentHash[2]
        var D: UInt32 = currentHash[3]

        var dTemp: UInt32 = 0

        // Main loop
        for j in 0..<k.count {
            var g = 0
            var F: UInt32 = 0

            switch j {
            case 0...15:
                F = (B & C) | ((~B) & D)
                g = j
                break
            case 16...31:
                F = (D & B) | (~D & C)
                g = (5 * j + 1) % 16
                break
            case 32...47:
                F = B ^ C ^ D
                g = (3 * j + 5) % 16
                break
            case 48...63:
                F = C ^ (B | (~D))
                g = (7 * j) % 16
                break
            default:
                break
            }
            dTemp = D
            D = C
            C = B

            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15 and get M[g] value
            let gAdvanced = g << 2

            var Mg = UInt32(chunk[chunk.startIndex &+ gAdvanced])
            Mg |= UInt32(chunk[chunk.startIndex &+ gAdvanced &+ 1]) << 8
            Mg |= UInt32(chunk[chunk.startIndex &+ gAdvanced &+ 2]) << 16
            Mg |= UInt32(chunk[chunk.startIndex &+ gAdvanced &+ 3]) << 24

            B = B &+ rotateLeft(A &+ F &+ k[j] &+ Mg, by: s[j])
            A = dTemp
        }

        currentHash[0] = currentHash[0] &+ A
        currentHash[1] = currentHash[1] &+ B
        currentHash[2] = currentHash[2] &+ C
        currentHash[3] = currentHash[3] &+ D
    }
}

extension MD5: Updatable {

    internal func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false) throws -> Array<UInt8> {
        accumulated += bytes

        if isLast {
            let lengthInBits = (processedBytesTotalCount + accumulated.count) * 8
            let lengthBytes = lengthInBits.bytes(totalBytes: 64 / 8) // A 64-bit representation of b

            // Step 1. Append padding
            bitPadding(to: &accumulated, blockSize: MD5.blockSize, allowance: 64 / 8)

            // Step 2. Append Length a 64-bit representation of lengthInBits
            accumulated += lengthBytes.reversed()
        }

        var processedBytes = 0
        for chunk in accumulated.batched(by: MD5.blockSize) {
            if isLast || (accumulated.count - processedBytes) >= MD5.blockSize {
                process(block: chunk, currentHash: &accumulatedHash)
                processedBytes += chunk.count
            }
        }
        accumulated.removeFirst(processedBytes)
        processedBytesTotalCount += processedBytes

        // output current hash
        var result = Array<UInt8>()
        result.reserveCapacity(MD5.digestLength)

        for hElement in accumulatedHash {
            let hLE = hElement.littleEndian
            result += Array<UInt8>(arrayLiteral: UInt8(hLE & 0xff), UInt8((hLE >> 8) & 0xff), UInt8((hLE >> 16) & 0xff), UInt8((hLE >> 24) & 0xff))
        }

        // reset hash value for instance
        if isLast {
            accumulatedHash = MD5.hashInitialValue
        }

        return result
    }
}
//
//  NoPadding.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

struct NoPadding: PaddingProtocol {

    init() {
    }

    func add(to data: Array<UInt8>, blockSize _: Int) -> Array<UInt8> {
        return data
    }

    func remove(from data: Array<UInt8>, blockSize _: Int?) -> Array<UInt8> {
        return data
    }
}
//
//  Padding.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

internal protocol PaddingProtocol {
    func add(to: Array<UInt8>, blockSize: Int) -> Array<UInt8>
    func remove(from: Array<UInt8>, blockSize: Int?) -> Array<UInt8>
}

internal enum Padding: PaddingProtocol {
    case noPadding, zeroPadding

    internal func add(to: Array<UInt8>, blockSize: Int) -> Array<UInt8> {
        switch self {
        case .noPadding:
            return NoPadding().add(to: to, blockSize: blockSize)
        case .zeroPadding:
            return ZeroPadding().add(to: to, blockSize: blockSize)
        }
    }

    internal func remove(from: Array<UInt8>, blockSize: Int?) -> Array<UInt8> {
        switch self {
        case .noPadding:
            return NoPadding().remove(from: from, blockSize: blockSize)
        case .zeroPadding:
            return ZeroPadding().remove(from: from, blockSize: blockSize)
        }
    }
}
//
//  SHA1.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

internal final class SHA1: DigestType {
    static let digestLength: Int = 20 // 160 / 8
    static let blockSize: Int = 64
    fileprivate static let hashInitialValue: ContiguousArray<UInt32> = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0]

    fileprivate var accumulated = Array<UInt8>()
    fileprivate var processedBytesTotalCount: Int = 0
    fileprivate var accumulatedHash: ContiguousArray<UInt32> = SHA1.hashInitialValue

    internal init() {
    }

    internal func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        do {
            return try update(withBytes: bytes.slice, isLast: true)
        } catch {
            return []
        }
    }

    fileprivate func process(block chunk: ArraySlice<UInt8>, currentHash hh: inout ContiguousArray<UInt32>) {
        // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
        // Extend the sixteen 32-bit words into eighty 32-bit words:
        let M = UnsafeMutablePointer<UInt32>.allocate(capacity: 80)
        M.initialize(to: 0, count: 80)
        defer {
            M.deinitialize(count: 80)
            M.deallocate(capacity: 80)
        }

        for x in 0..<80 {
            switch x {
            case 0...15:
                let start = chunk.startIndex.advanced(by: x * 4) // * MemoryLayout<UInt32>.size
                M[x] = UInt32(bytes: chunk, fromIndex: start)
                break
            default:
                M[x] = rotateLeft(M[x - 3] ^ M[x - 8] ^ M[x - 14] ^ M[x - 16], by: 1)
                break
            }
        }

        var A = hh[0]
        var B = hh[1]
        var C = hh[2]
        var D = hh[3]
        var E = hh[4]

        // Main loop
        for j in 0...79 {
            var f: UInt32 = 0
            var k: UInt32 = 0

            switch j {
            case 0...19:
                f = (B & C) | ((~B) & D)
                k = 0x5a827999
                break
            case 20...39:
                f = B ^ C ^ D
                k = 0x6ed9eba1
                break
            case 40...59:
                f = (B & C) | (B & D) | (C & D)
                k = 0x8f1bbcdc
                break
            case 60...79:
                f = B ^ C ^ D
                k = 0xca62c1d6
                break
            default:
                break
            }

            let temp = rotateLeft(A, by: 5) &+ f &+ E &+ M[j] &+ k
            E = D
            D = C
            C = rotateLeft(B, by: 30)
            B = A
            A = temp
        }

        hh[0] = hh[0] &+ A
        hh[1] = hh[1] &+ B
        hh[2] = hh[2] &+ C
        hh[3] = hh[3] &+ D
        hh[4] = hh[4] &+ E
    }
}

extension SHA1: Updatable {

    internal func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false) throws -> Array<UInt8> {
        accumulated += bytes

        if isLast {
            let lengthInBits = (processedBytesTotalCount + accumulated.count) * 8
            let lengthBytes = lengthInBits.bytes(totalBytes: 64 / 8) // A 64-bit representation of b

            // Step 1. Append padding
            bitPadding(to: &accumulated, blockSize: SHA1.blockSize, allowance: 64 / 8)

            // Step 2. Append Length a 64-bit representation of lengthInBits
            accumulated += lengthBytes
        }

        var processedBytes = 0
        for chunk in accumulated.batched(by: SHA1.blockSize) {
            if isLast || (accumulated.count - processedBytes) >= SHA1.blockSize {
                process(block: chunk, currentHash: &accumulatedHash)
                processedBytes += chunk.count
            }
        }
        accumulated.removeFirst(processedBytes)
        processedBytesTotalCount += processedBytes

        // output current hash
        var result = Array<UInt8>(repeating: 0, count: SHA1.digestLength)
        var pos = 0
        for idx in 0..<accumulatedHash.count {
            let h = accumulatedHash[idx].bigEndian
            result[pos] = UInt8(h & 0xff)
            result[pos + 1] = UInt8((h >> 8) & 0xff)
            result[pos + 2] = UInt8((h >> 16) & 0xff)
            result[pos + 3] = UInt8((h >> 24) & 0xff)
            pos += 4
        }

        // reset hash value for instance
        if isLast {
            accumulatedHash = SHA1.hashInitialValue
        }

        return result
    }
}
//
//  SHA2.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

//  TODO: generic for process32/64 (UInt32/UInt64)
//

internal final class SHA2: DigestType {
    let variant: Variant
    let size: Int
    let blockSize: Int
    let digestLength: Int
    private let k: Array<UInt64>

    fileprivate var accumulated = Array<UInt8>()
    fileprivate var processedBytesTotalCount: Int = 0
    fileprivate var accumulatedHash32 = Array<UInt32>()
    fileprivate var accumulatedHash64 = Array<UInt64>()

    internal enum Variant: RawRepresentable {
        case sha256, sha512

        internal var digestLength: Int {
            return rawValue / 8
        }

        internal var blockSize: Int {
            switch self {
            case .sha256:
                return 64
            case .sha512:
                return 128
            }
        }

        internal typealias RawValue = Int
        internal var rawValue: RawValue {
            switch self {
            case .sha256:
                return 256
            case .sha512:
                return 512
            }
        }

        internal init?(rawValue: RawValue) {
            switch rawValue {
            case 256:
                self = .sha256
                break
            case 512:
                self = .sha512
                break
            default:
                return nil
            }
        }

        fileprivate var h: Array<UInt64> {
            switch self {
            case .sha256:
                return [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
            case .sha512:
                return [0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1, 0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179]
            }
        }

        fileprivate var finalLength: Int {
            return Int.max
        }
    }

    internal init(variant: SHA2.Variant) {
        self.variant = variant
        switch self.variant {
        case .sha256:
            accumulatedHash32 = variant.h.map { UInt32($0) } // FIXME: UInt64 for process64
            blockSize = variant.blockSize
            size = variant.rawValue
            digestLength = variant.digestLength
            k = [
                0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
                0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
                0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
                0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
                0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
                0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
                0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
            ]
        case .sha512:
            accumulatedHash64 = variant.h
            blockSize = variant.blockSize
            size = variant.rawValue
            digestLength = variant.digestLength
            k = [
                0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538,
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
                0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817,
            ]
        }
    }

    internal func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        do {
            return try update(withBytes: bytes.slice, isLast: true)
        } catch {
            return []
        }
    }

    fileprivate func process64(block chunk: ArraySlice<UInt8>, currentHash hh: inout Array<UInt64>) {
        // break chunk into sixteen 64-bit words M[j], 0 ≤ j ≤ 15, big-endian
        // Extend the sixteen 64-bit words into eighty 64-bit words:
        let M = UnsafeMutablePointer<UInt64>.allocate(capacity: k.count)
        M.initialize(to: 0, count: k.count)
        defer {
            M.deinitialize(count: self.k.count)
            M.deallocate(capacity: self.k.count)
        }
        for x in 0..<k.count {
            switch x {
            case 0...15:
                let start = chunk.startIndex.advanced(by: x * 8) // * MemoryLayout<UInt64>.size
                M[x] = UInt64(bytes: chunk, fromIndex: start)
                break
            default:
                let s0 = rotateRight(M[x - 15], by: 1) ^ rotateRight(M[x - 15], by: 8) ^ (M[x - 15] >> 7)
                let s1 = rotateRight(M[x - 2], by: 19) ^ rotateRight(M[x - 2], by: 61) ^ (M[x - 2] >> 6)
                M[x] = M[x - 16] &+ s0 &+ M[x - 7] &+ s1
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
        for j in 0..<k.count {
            let s0 = rotateRight(A, by: 28) ^ rotateRight(A, by: 34) ^ rotateRight(A, by: 39)
            let maj = (A & B) ^ (A & C) ^ (B & C)
            let t2 = s0 &+ maj
            let s1 = rotateRight(E, by: 14) ^ rotateRight(E, by: 18) ^ rotateRight(E, by: 41)
            let ch = (E & F) ^ ((~E) & G)
            let t1 = H &+ s1 &+ ch &+ k[j] &+ UInt64(M[j])

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

    // mutating currentHash in place is way faster than returning new result
    fileprivate func process32(block chunk: ArraySlice<UInt8>, currentHash hh: inout Array<UInt32>) {
        // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
        // Extend the sixteen 32-bit words into sixty-four 32-bit words:
        let M = UnsafeMutablePointer<UInt32>.allocate(capacity: k.count)
        M.initialize(to: 0, count: k.count)
        defer {
            M.deinitialize(count: self.k.count)
            M.deallocate(capacity: self.k.count)
        }

        for x in 0..<k.count {
            switch x {
            case 0...15:
                let start = chunk.startIndex.advanced(by: x * 4) // * MemoryLayout<UInt32>.size
                M[x] = UInt32(bytes: chunk, fromIndex: start)
                break
            default:
                let s0 = rotateRight(M[x - 15], by: 7) ^ rotateRight(M[x - 15], by: 18) ^ (M[x - 15] >> 3)
                let s1 = rotateRight(M[x - 2], by: 17) ^ rotateRight(M[x - 2], by: 19) ^ (M[x - 2] >> 10)
                M[x] = M[x - 16] &+ s0 &+ M[x - 7] &+ s1
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
        for j in 0..<k.count {
            let s0 = rotateRight(A, by: 2) ^ rotateRight(A, by: 13) ^ rotateRight(A, by: 22)
            let maj = (A & B) ^ (A & C) ^ (B & C)
            let t2 = s0 &+ maj
            let s1 = rotateRight(E, by: 6) ^ rotateRight(E, by: 11) ^ rotateRight(E, by: 25)
            let ch = (E & F) ^ ((~E) & G)
            let t1 = H &+ s1 &+ ch &+ UInt32(k[j]) &+ M[j]

            H = G
            G = F
            F = E
            E = D &+ t1
            D = C
            C = B
            B = A
            A = t1 &+ t2
        }

        hh[0] = hh[0] &+ A
        hh[1] = hh[1] &+ B
        hh[2] = hh[2] &+ C
        hh[3] = hh[3] &+ D
        hh[4] = hh[4] &+ E
        hh[5] = hh[5] &+ F
        hh[6] = hh[6] &+ G
        hh[7] = hh[7] &+ H
    }
}

extension SHA2: Updatable {

    internal func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false) throws -> Array<UInt8> {
        accumulated += bytes

        if isLast {
            let lengthInBits = (processedBytesTotalCount + accumulated.count) * 8
            let lengthBytes = lengthInBits.bytes(totalBytes: blockSize / 8) // A 64-bit/128-bit representation of b. blockSize fit by accident.

            // Step 1. Append padding
            bitPadding(to: &accumulated, blockSize: blockSize, allowance: blockSize / 8)

            // Step 2. Append Length a 64-bit representation of lengthInBits
            accumulated += lengthBytes
        }

        var processedBytes = 0
        for chunk in accumulated.batched(by: blockSize) {
            if isLast || (accumulated.count - processedBytes) >= blockSize {
                switch variant {
                case .sha256:
                    process32(block: chunk, currentHash: &accumulatedHash32)
                case .sha512:
                    process64(block: chunk, currentHash: &accumulatedHash64)
                }
                processedBytes += chunk.count
            }
        }
        accumulated.removeFirst(processedBytes)
        processedBytesTotalCount += processedBytes

        // output current hash
        var result = Array<UInt8>(repeating: 0, count: variant.digestLength)
        switch variant {
        case .sha256:
            var pos = 0
            for idx in 0..<accumulatedHash32.count where idx < variant.finalLength {
                let h = accumulatedHash32[idx].bigEndian
                result[pos] = UInt8(h & 0xff)
                result[pos + 1] = UInt8((h >> 8) & 0xff)
                result[pos + 2] = UInt8((h >> 16) & 0xff)
                result[pos + 3] = UInt8((h >> 24) & 0xff)
                pos += 4
            }
        case .sha512:
            var pos = 0
            for idx in 0..<accumulatedHash64.count where idx < variant.finalLength {
                let h = accumulatedHash64[idx].bigEndian
                result[pos] = UInt8(h & 0xff)
                result[pos + 1] = UInt8((h >> 8) & 0xff)
                result[pos + 2] = UInt8((h >> 16) & 0xff)
                result[pos + 3] = UInt8((h >> 24) & 0xff)
                result[pos + 4] = UInt8((h >> 32) & 0xff)
                result[pos + 5] = UInt8((h >> 40) & 0xff)
                result[pos + 6] = UInt8((h >> 48) & 0xff)
                result[pos + 7] = UInt8((h >> 56) & 0xff)
                pos += 8
            }
        }

        // reset hash value for instance
        if isLast {
            switch variant {
            case .sha256:
                accumulatedHash32 = variant.h.lazy.map { UInt32($0) } // FIXME: UInt64 for process64
            case .sha512:
                accumulatedHash64 = variant.h
            }
        }

        return result
    }
}
//
//  StringExtension.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/** String extension */
extension String {

    internal var bytes: Array<UInt8> {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }

    internal func md5() -> String {
        return bytes.md5().toHexString()
    }

    internal func sha1() -> String {
        return bytes.sha1().toHexString()
    }

    internal func sha256() -> String {
        return bytes.sha256().toHexString()
    }

    internal func sha512() -> String {
        return bytes.sha512().toHexString()
    }

    /// - parameter authenticator: Instance of `Authenticator`
    /// - returns: hex string of string
    internal func authenticate<A: Authenticator>(with authenticator: A) throws -> String {
        return try bytes.authenticate(with: authenticator).toHexString()
    }
}
//
//  UInt16+Extension.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/** array of bytes */
extension UInt16 {

    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt16(bytes: bytes, fromIndex: bytes.startIndex)
    }

    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }

        let count = bytes.count

        let val0 = count > 0 ? UInt16(bytes[index.advanced(by: 0)]) << 8 : 0
        let val1 = count > 1 ? UInt16(bytes[index.advanced(by: 1)]) : 0

        self = val0 | val1
    }
}
//
//  UInt32Extension.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

#if os(Linux) || os(Android) || os(FreeBSD)
    import Glibc
#else
    import Darwin
#endif

protocol _UInt32Type {}
extension UInt32: _UInt32Type {}

/** array of bytes */
extension UInt32 {

    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt32(bytes: bytes, fromIndex: bytes.startIndex)
    }

    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }

        let count = bytes.count

        let val0 = count > 0 ? UInt32(bytes[index.advanced(by: 0)]) << 24 : 0
        let val1 = count > 1 ? UInt32(bytes[index.advanced(by: 1)]) << 16 : 0
        let val2 = count > 2 ? UInt32(bytes[index.advanced(by: 2)]) << 8 : 0
        let val3 = count > 3 ? UInt32(bytes[index.advanced(by: 3)]) : 0

        self = val0 | val1 | val2 | val3
    }
}
//
//  UInt64Extension.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/** array of bytes */
extension UInt64 {

    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt64(bytes: bytes, fromIndex: bytes.startIndex)
    }

    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }

        let count = bytes.count

        let val0 = count > 0 ? UInt64(bytes[index.advanced(by: 0)]) << 56 : 0
        let val1 = count > 0 ? UInt64(bytes[index.advanced(by: 1)]) << 48 : 0
        let val2 = count > 0 ? UInt64(bytes[index.advanced(by: 2)]) << 40 : 0
        let val3 = count > 0 ? UInt64(bytes[index.advanced(by: 3)]) << 32 : 0
        let val4 = count > 0 ? UInt64(bytes[index.advanced(by: 4)]) << 24 : 0
        let val5 = count > 0 ? UInt64(bytes[index.advanced(by: 5)]) << 16 : 0
        let val6 = count > 0 ? UInt64(bytes[index.advanced(by: 6)]) << 8 : 0
        let val7 = count > 0 ? UInt64(bytes[index.advanced(by: 7)]) : 0

        self = val0 | val1 | val2 | val3 | val4 | val5 | val6 | val7
    }
}
//
//  ByteExtension.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

#if os(Linux) || os(Android) || os(FreeBSD)
    import Glibc
#else
    import Darwin
#endif

internal protocol _UInt8Type {}
extension UInt8: _UInt8Type {}

/** casting */
extension UInt8 {

    /** cast because UInt8(<UInt32>) because std initializer crash if value is > byte */
    static func with(value: UInt64) -> UInt8 {
        let tmp = value & 0xff
        return UInt8(tmp)
    }

    static func with(value: UInt32) -> UInt8 {
        let tmp = value & 0xff
        return UInt8(tmp)
    }

    static func with(value: UInt16) -> UInt8 {
        let tmp = value & 0xff
        return UInt8(tmp)
    }
}

/** Bits */
extension UInt8 {

    init(bits: [Bit]) {
        self.init(integerFrom(bits) as UInt8)
    }

    /** array of bits */
    internal func bits() -> [Bit] {
        let totalBitsCount = MemoryLayout<UInt8>.size * 8

        var bitsArray = [Bit](repeating: Bit.zero, count: totalBitsCount)

        for j in 0..<totalBitsCount {
            let bitVal: UInt8 = 1 << UInt8(totalBitsCount - 1 - j)
            let check = self & bitVal

            if check != 0 {
                bitsArray[j] = Bit.one
            }
        }
        return bitsArray
    }

    internal func bits() -> String {
        var s = String()
        let arr: [Bit] = bits()
        for idx in arr.indices {
            s += (arr[idx] == Bit.one ? "1" : "0")
            if idx.advanced(by: 1) % 8 == 0 { s += " " }
        }
        return s
    }
}
//
//  Updatable.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/// A type that supports incremental updates. For example Digest or Cipher may be updatable
/// and calculate result incerementally.
internal protocol Updatable {
    /// Update given bytes in chunks.
    ///
    /// - parameter bytes: Bytes to process.
    /// - parameter isLast: Indicate if given chunk is the last one. No more updates after this call.
    /// - returns: Processed data or empty array.
    mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool) throws -> Array<UInt8>

    /// Update given bytes in chunks.
    ///
    /// - Parameters:
    ///   - bytes: Bytes to process.
    ///   - isLast: Indicate if given chunk is the last one. No more updates after this call.
    ///   - output: Resulting bytes callback.
    /// - Returns: Processed data or empty array.
    mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool, output: (_ bytes: Array<UInt8>) -> Void) throws

    /// Finish updates. This may apply padding.
    /// - parameter bytes: Bytes to process
    /// - returns: Processed data.
    mutating func finish(withBytes bytes: ArraySlice<UInt8>) throws -> Array<UInt8>

    /// Finish updates. This may apply padding.
    /// - parameter bytes: Bytes to process
    /// - parameter output: Resulting data
    /// - returns: Processed data.
    mutating func finish(withBytes bytes: ArraySlice<UInt8>, output: (_ bytes: Array<UInt8>) -> Void) throws
}

extension Updatable {

    internal mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false, output: (_ bytes: Array<UInt8>) -> Void) throws {
        let processed = try update(withBytes: bytes, isLast: isLast)
        if !processed.isEmpty {
            output(processed)
        }
    }

    internal mutating func finish(withBytes bytes: ArraySlice<UInt8>) throws -> Array<UInt8> {
        return try update(withBytes: bytes, isLast: true)
    }

    internal mutating func finish() throws -> Array<UInt8> {
        return try update(withBytes: [], isLast: true)
    }

    internal mutating func finish(withBytes bytes: ArraySlice<UInt8>, output: (_ bytes: Array<UInt8>) -> Void) throws {
        let processed = try update(withBytes: bytes, isLast: true)
        if !processed.isEmpty {
            output(processed)
        }
    }

    internal mutating func finish(output: (Array<UInt8>) -> Void) throws {
        try finish(withBytes: [], output: output)
    }
}

extension Updatable {

    internal mutating func update(withBytes bytes: Array<UInt8>, isLast: Bool = false) throws -> Array<UInt8> {
        return try update(withBytes: bytes.slice, isLast: isLast)
    }

    internal mutating func update(withBytes bytes: Array<UInt8>, isLast: Bool = false, output: (_ bytes: Array<UInt8>) -> Void) throws {
        return try update(withBytes: bytes.slice, isLast: isLast, output: output)
    }

    internal mutating func finish(withBytes bytes: Array<UInt8>) throws -> Array<UInt8> {
        return try finish(withBytes: bytes.slice)
    }

    internal mutating func finish(withBytes bytes: Array<UInt8>, output: (_ bytes: Array<UInt8>) -> Void) throws {
        return try finish(withBytes: bytes.slice, output: output)
    }
}
//
//  Utils.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

@_transparent
func rotateLeft(_ value: UInt8, by: UInt8) -> UInt8 {
    return ((value << by) & 0xff) | (value >> (8 - by))
}

@_transparent
func rotateLeft(_ value: UInt16, by: UInt16) -> UInt16 {
    return ((value << by) & 0xffff) | (value >> (16 - by))
}

@_transparent
func rotateLeft(_ value: UInt32, by: UInt32) -> UInt32 {
    return ((value << by) & 0xffffffff) | (value >> (32 - by))
}

@_transparent
func rotateLeft(_ value: UInt64, by: UInt64) -> UInt64 {
    return (value << by) | (value >> (64 - by))
}

@_transparent
func rotateRight(_ value: UInt16, by: UInt16) -> UInt16 {
    return (value >> by) | (value << (16 - by))
}

@_transparent
func rotateRight(_ value: UInt32, by: UInt32) -> UInt32 {
    return (value >> by) | (value << (32 - by))
}

@_transparent
func rotateRight(_ value: UInt64, by: UInt64) -> UInt64 {
    return ((value >> by) | (value << (64 - by)))
}

@_transparent
func reversed(_ uint8: UInt8) -> UInt8 {
    var v = uint8
    v = (v & 0xf0) >> 4 | (v & 0x0f) << 4
    v = (v & 0xcc) >> 2 | (v & 0x33) << 2
    v = (v & 0xaa) >> 1 | (v & 0x55) << 1
    return v
}

@_transparent
func reversed(_ uint32: UInt32) -> UInt32 {
    var v = uint32
    v = ((v >> 1) & 0x55555555) | ((v & 0x55555555) << 1)
    v = ((v >> 2) & 0x33333333) | ((v & 0x33333333) << 2)
    v = ((v >> 4) & 0x0f0f0f0f) | ((v & 0x0f0f0f0f) << 4)
    v = ((v >> 8) & 0x00ff00ff) | ((v & 0x00ff00ff) << 8)
    v = ((v >> 16) & 0xffff) | ((v & 0xffff) << 16)
    return v
}

func xor<T, V>(_ left: T, _ right: V) -> ArraySlice<UInt8> where T: RandomAccessCollection, V: RandomAccessCollection, T.Element == UInt8, T.Index == Int, T.IndexDistance == Int, V.Element == UInt8, V.IndexDistance == Int, V.Index == Int {
    return xor(left, right).slice
}

func xor<T, V>(_ left: T, _ right: V) -> Array<UInt8> where T: RandomAccessCollection, V: RandomAccessCollection, T.Element == UInt8, T.Index == Int, T.IndexDistance == Int, V.Element == UInt8, V.IndexDistance == Int, V.Index == Int {
    let length = Swift.min(left.count, right.count)

    let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
    buf.initialize(to: 0, count: length)
    defer {
        buf.deinitialize()
        buf.deallocate(capacity: length)
    }

    // xor
    for i in 0..<length {
        buf[i] = left[left.startIndex.advanced(by: i)] ^ right[right.startIndex.advanced(by: i)]
    }

    return Array(UnsafeBufferPointer(start: buf, count: length))
}

/**
 ISO/IEC 9797-1 Padding method 2.
 Add a single bit with value 1 to the end of the data.
 If necessary add bits with value 0 to the end of the data until the padded data is a multiple of blockSize.
 - parameters:
 - blockSize: Padding size in bytes.
 - allowance: Excluded trailing number of bytes.
 */
@inline(__always)
func bitPadding(to data: inout Array<UInt8>, blockSize: Int, allowance: Int = 0) {
    let msgLength = data.count
    // Step 1. Append Padding Bits
    // append one bit (UInt8 with one bit) to message
    data.append(0x80)

    // Step 2. append "0" bit until message length in bits ≡ 448 (mod 512)
    let max = blockSize - allowance // 448, 986
    if msgLength % blockSize < max { // 448
        data += Array<UInt8>(repeating: 0, count: max - 1 - (msgLength % blockSize))
    } else {
        data += Array<UInt8>(repeating: 0, count: blockSize + max - 1 - (msgLength % blockSize))
    }
}
//
//  ZeroPadding.swift
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

/// All the bytes that are required to be padded are padded with zero.
/// Zero padding may not be reversible if the original file ends with one or more zero bytes.
struct ZeroPadding: PaddingProtocol {

    init() {
    }

    func add(to bytes: Array<UInt8>, blockSize: Int) -> Array<UInt8> {
        let paddingCount = blockSize - (bytes.count % blockSize)
        if paddingCount > 0 {
            return bytes + Array<UInt8>(repeating: 0, count: paddingCount)
        }
        return bytes
    }

    func remove(from bytes: Array<UInt8>, blockSize _: Int?) -> Array<UInt8> {
        for (idx, value) in bytes.reversed().enumerated() {
            if value != 0 {
                return Array(bytes[0..<bytes.count - idx])
            }
        }
        return bytes
    }
}
