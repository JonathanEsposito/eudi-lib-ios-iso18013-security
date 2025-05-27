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

/// The role for the session encryption object.
public enum SessionRole: String, Sendable {
	/// mdoc reader (verifier) role
    case reader
	/// mdoc (holder) role
    case mdoc
}

extension SessionRole {
    
    var encryptionSharedInfo: Data {
        switch self {
        case .reader: Data("SKReader".utf8)
        case .mdoc: Data("SKDevice".utf8)
        }
    }
    
    var decryptionSharedInfo: Data {
        switch self {
        case .reader: Data("SKDevice".utf8)
        case .mdoc: Data("SKReader".utf8)
        }
    }
    
    var encryptionIdentifier: [UInt8] {
        switch self {
        case .reader: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        case .mdoc: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
        }
    }
    
    var decryptionIdentifier: [UInt8] {
        switch self {
        case .reader: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
        case .mdoc: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        }
    }
    
}