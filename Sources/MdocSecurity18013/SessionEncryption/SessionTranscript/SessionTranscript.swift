//
//  SessionTranscript.swift
//  MdocSecurity18013
//
//  Created by Jonathan Esposito on 27/05/2025.
//

import Foundation

public protocol SessionTranscript {
    var bytes: [UInt8] { get }
    func toCBOR(options: CBOROptions) -> CBOR
}