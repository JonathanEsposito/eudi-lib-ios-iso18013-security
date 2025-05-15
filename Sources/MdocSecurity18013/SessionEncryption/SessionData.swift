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
import MdocDataModel18013
import SwiftCBOR
import Logging
import OrderedCollections

/// Message data transfered between mDL and mDL reader
public struct SessionData: Sendable {
    
	public let data: [UInt8]?
	public let status: Status?
	
	enum CodingKeys: String, CodingKey {
		case data
		case status
	}

	public init(cipher_data: [UInt8]? = nil, status: Status? = nil) {
		self.data = cipher_data
		self.status = status
	}
}

extension SessionData: CBORDecodable {
	public init?(cbor: CBOR) {
		guard case let .map(values) = cbor else { logger.error("Session data must be a map"); return nil  }
        if case let .byteString(bs) = values[.utf8String(CodingKeys.data.rawValue)] { data = bs } else { logger.error("SessionData: Missing data"); data = nil  }
        if case let .unsignedInt(s) = values[.utf8String(CodingKeys.status.rawValue)] { status = Status(rawValue: s) } else { logger.info("SessionData: Missing status"); status = nil  }
	}
}

extension SessionData: CBOREncodable {
	public func toCBOR(options: CBOROptions) -> CBOR {
		var res = OrderedDictionary<CBOR, CBOR>()
        if let d = data { res[CBOR.utf8String(CodingKeys.data.rawValue)] = CBOR.byteString(d) }
        if let st = status { res[CBOR.utf8String(CodingKeys.status.rawValue)] = CBOR.unsignedInt(st.rawValue) }
		return .map(res)
	}
}

extension SessionData {
    
    public enum Status: Sendable {
        case errorSessionEncryption
        case errorCBORDecoding
        case sessionTermination
        case unknown(UInt64)
        
        var rawValue: UInt64 {
            switch self {
            case .errorSessionEncryption: StatusRawValue.errorSessionEncryption.rawValue
            case .errorCBORDecoding: StatusRawValue.errorCBORDecoding.rawValue
            case .sessionTermination: StatusRawValue.sessionTermination.rawValue
            case .unknown(let rawValue): rawValue
            }
        }
        
        enum StatusRawValue: UInt64 {
            case errorSessionEncryption = 10
            case errorCBORDecoding = 11
            case sessionTermination = 20
            
            var status: Status {
                switch self {
                case .errorSessionEncryption: .errorSessionEncryption
                case .errorCBORDecoding: .errorCBORDecoding
                case .sessionTermination: .sessionTermination
                }
            }
        }
        
        public init(rawValue: UInt64) {
            self = StatusRawValue(rawValue: rawValue)?.status ?? .unknown(rawValue)
        }
    }
    
}
