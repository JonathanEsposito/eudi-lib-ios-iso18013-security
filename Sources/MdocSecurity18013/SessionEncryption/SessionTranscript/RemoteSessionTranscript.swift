//
//  RemoteSessionTranscript.swift
//  MdocSecurity18013
//
//  Created by Jonathan Esposito on 27/05/2025.
//

import Foundation
import SwiftCBOR

public struct RemoteSessionTranscript: CBOREncodable, SessionTranscript {
    
    // handover object
    let handOver: CBOR
    
    public init(handOver: CBOR) {
        self.handOver = handOver
    }
    
    public var bytes: [UInt8] {
        taggedEncoded.encode(options: CBOROptions())
    }
    
    public func toCBOR(options: CBOROptions) -> CBOR {
        .array([CBOR.null, CBOR.null, handOver])
    }
    
}
