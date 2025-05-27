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

//  ProximitySessionTranscript.swift

import Foundation
import MdocDataModel18013
import SwiftCBOR

/// SessionTranscript = [DeviceEngagementBytes,EReaderKeyBytes,Handover]
public struct ProximitySessionTranscript: SessionTranscript {
	/// device engagement bytes (NOT tagged)
    private let deviceEngagement: DeviceEngagement
	/// reader key bytes ( NOT tagged)
    private let eReaderKey: [UInt8]
	// handover object
    private let handOver: CBOR
    
    public init(deviceEngagement: DeviceEngagement, eReaderKey: [UInt8], handOver: CBOR) {
		self.deviceEngagement = deviceEngagement
		self.eReaderKey = eReaderKey
		self.handOver = handOver
	}
    
    /// SessionTranscript = [DeviceEngagementBytes,EReaderKeyBytes,Handover]
    public var bytes: [UInt8] {
        taggedEncoded.encode(options: CBOROptions())
    }
    
}

extension ProximitySessionTranscript: CBOREncodable {
	public func toCBOR(options: CBOROptions) -> CBOR {
        return .array(
            [
                (deviceEngagement.qrCoded ?? deviceEngagement.encode(options: CBOROptions())).taggedEncoded,
                eReaderKey.taggedEncoded,
                handOver
            ]
        )
	}
}
