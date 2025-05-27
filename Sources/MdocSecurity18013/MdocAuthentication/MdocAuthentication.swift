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

/// Implements mdoc authentication
/// 
/// The security objective of mdoc authentication is to prevent cloning of the mdoc and to mitigate man in the middle attacks.
/// Currently the mdoc side is implemented (generation of device-auth)
/// Initialized from the session transcript object, the device private key and the reader ephemeral public key 
/// 
/// ```swift
/// let mdocAuth = MdocAuthentication(transcript: sessionEncr.transcript, authKeys: authKeys)
/// ```
public struct MdocAuthentication {
	
    private let transcript: SessionTranscript
    private let authKeys: CoseKeyExchange
	
	public init(transcript: SessionTranscript, authKeys: CoseKeyExchange) {
		self.transcript = transcript
		self.authKeys = authKeys
	}
	
	/// Generate a ``DeviceAuth`` structure used for mdoc-authentication
	/// - Parameters:
	///   - docType: docType of the document to authenticate
	///   - deviceNameSpacesRawData: device-name spaces raw data. Usually is a CBOR-encoded empty dictionary
	///   - bUseDeviceSign: Specify true for device authentication (false is default)
	/// - Returns: DeviceAuth instance
    public func getDeviceAuthForTransfer(docType: String, deviceNameSpacesRawData: [UInt8] = [0xA0]) throws -> DeviceAuth {
		let deviceAuthentication = DeviceAuthentication(sessionTranscript: transcript, docType: docType, deviceNameSpacesRawData: deviceNameSpacesRawData)
		let contentBytes = deviceAuthentication.toCBOR(options: CBOROptions()).taggedEncoded.encode(options: CBOROptions())
		let coseRes: Cose
        
        switch authKeys.privateKey {
        case .signing(let walletSigningKey): // DeviceSignature
            coseRes = try Cose.makeDetachedCoseSign1(deviceKey: walletSigningKey, payloadData: Data(contentBytes))
        case .encryption(let walletEncryptionKey): // MAC
            let symmetricKey = try walletEncryptionKey.hkdfDerivedSymmetricKey(salt: transcript.bytes, publicKey: authKeys.publicKey.getx963Representation(), sharedInfo: Data("EMacKey".utf8))
            coseRes = Cose.makeDetachedCoseMac0(payloadData: Data(contentBytes), key: symmetricKey, alg: walletEncryptionKey.curve.defaultMacAlgorithm)
        }
        
		return DeviceAuth(coseMacOrSignature: coseRes)
	}
    
}
