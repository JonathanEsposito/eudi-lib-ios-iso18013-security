/*
Copyright (c) 2023 European Commission

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import Foundation
import CryptoKit
import MdocDataModel18013
import SwiftCBOR

/// Session encryption uses standard ephemeral key ECDH to establish session keys for authenticated symmetric encryption.
/// The ``SessionEncryption`` struct implements session encryption (for the mDoc currently)
/// It is initialized from a) the session establishment data received from the mdoc reader, b) the device engagement data generated from the mdoc and c) the handover data.
/// 
/// ```swift
/// var se = SessionEncryption(se: sessionEstablishmentObject, de: deviceEngagementObject, handOver: handOverObject)
/// ```
public struct SessionEncryption {
    
    enum SessionEncryptionError: Error {
        case deviceRequestFailedToDecrypt
    }
    
    public let publicKey: CoseKey
    public let transcript: SessionTranscript
    
    private let sessionRole: SessionRole
    private var sessionCounter: UInt32 = 1
    private let privateKey: WalletEncryptionKey
	
	/// Initialization of session encryption for the mdoc
	/// - Parameters:
	///   - se: session establishment data from the mdoc reader
	///   - de: device engagement created by the mdoc
	///   - handOver: handover object according to the transfer protocol
	public init?(se: SessionEstablishment, de: DeviceEngagement, handOver: CBOR) {
		sessionRole = .mdoc
		guard let pk = de.privateKey else { logger.error("Device engagement for mdoc must have the private key"); return nil}
        self.transcript = ProximitySessionTranscript(deviceEngagement: de, eReaderKey: se.eReaderKeyRawData, handOver: handOver)
        
        self.publicKey = se.eReaderKey
        self.privateKey = pk
	}
    
    /// Initialization of session encryption for the reader
    /// - Parameters:
    ///   - eReaderKey: session establishment data from the mdoc reader
    ///   - deviceEngagementData: device engagement as contend of the scanned  qr-code
    ///   - handOver: handover object according to the transfer protocol
    public init(eReaderKey: WalletEncryptionKey, deviceEngagement: DeviceEngagement, handOver: CBOR) {
        self.sessionRole = .reader
        let eDeviceKey = deviceEngagement.security.deviceKey
        self.publicKey = eDeviceKey
        self.privateKey = eReaderKey
        self.transcript = ProximitySessionTranscript(deviceEngagement: deviceEngagement, eReaderKey: eReaderKey.publicCoseKey.encode(), handOver: handOver)
    }
	
	/// Encrypt data using current nonce as described in 9.1.1.5 Cryptographic operations
	mutating public func encrypt(_ data: [UInt8]) throws -> [UInt8] {
        let nonce = try makeNonce(sessionCounter, identifier: sessionRole.encryptionIdentifier)
        let symmetricKey = try privateKey.hkdfDerivedSymmetricKey(salt: transcript.bytes, publicKey: publicKey.getx963Representation(), sharedInfo: sessionRole.encryptionSharedInfo)
		guard let encryptedContent = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce).combined else { throw SessionEncryptionError.deviceRequestFailedToDecrypt }
		if sessionRole == .mdoc { sessionCounter += 1 }
		return [UInt8](encryptedContent.dropFirst(12))
	}
	
	/// Decrypts cipher data using the symmetric key
	mutating public func decrypt(_ ciphertext: [UInt8]) throws -> [UInt8] {
        let nonce = try makeNonce(sessionCounter, identifier: sessionRole.decryptionIdentifier)
		let sealedBox = try AES.GCM.SealedBox(combined: nonce + ciphertext)
        let symmetricKey = try privateKey.hkdfDerivedSymmetricKey(salt: transcript.bytes, publicKey: publicKey.getx963Representation(), sharedInfo: sessionRole.decryptionSharedInfo)
		let decryptedContent = try AES.GCM.open(sealedBox, using: symmetricKey)
		return [UInt8](decryptedContent)
	}
    
    // MARK: - Private Methods
    
    /// Make nonce function to initialize the encryption or decryption
    ///
    /// - Parameters:
    ///   - counter: The message counter value shall be a 4-byte big-endian unsigned integer. For the first encryption with a session key, the message counter shall be set to 1. Before each following encryption with the same key, the message counter value shall be increased by 1
    ///   - isEncrypt: is for encrypt?
    /// - Returns: The IV (Initialization Vector) used for the encryption.
    private func makeNonce(_ counter: UInt32, identifier: [UInt8]) throws -> AES.GCM.Nonce {
        var dataNonce = Data()
        dataNonce.append(Data(identifier))
        dataNonce.append(Data(counter.byteArrayLittleEndian))
        let nonce = try AES.GCM.Nonce(data: dataNonce)
        return nonce
    }
	
}
