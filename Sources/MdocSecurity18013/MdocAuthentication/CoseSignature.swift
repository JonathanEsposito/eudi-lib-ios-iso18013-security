import Foundation
import CryptoKit
import MdocDataModel18013

extension Cose {
	
	public static func makeDetachedCoseSign1(payloadData: Data, deviceKey: CoseKeyPrivate, alg: Cose.VerifyAlgorithm) -> Cose {
		let coseIn = Cose(type: .sign1, algorithm: alg.rawValue, payloadData: payloadData)
		let dataToSign = coseIn.signatureStruct!
		// return COSE_SIGN1 struct
		return Cose(type: .sign1, algorithm: alg.rawValue, signature: computeSignatureValue(dataToSign, deviceKey: deviceKey, alg: alg))
	}
	
	public static func computeSignatureValue(_ dataToSign: Data, deviceKey: CoseKeyPrivate, alg: Cose.VerifyAlgorithm) -> Data {
		let sign1Value: Data
		switch alg {
		case .es256:
			let signingKey = try! P256.Signing.PrivateKey(x963Representation: deviceKey.getx963Representation())
			sign1Value = (try! signingKey.signature(for: dataToSign)).rawRepresentation
		case .es384:
			let signingKey = try! P384.Signing.PrivateKey(x963Representation: deviceKey.getx963Representation())
			sign1Value = (try! signingKey.signature(for: dataToSign)).rawRepresentation
		case .es512:
			let signingKey = try! P521.Signing.PrivateKey(x963Representation: deviceKey.getx963Representation())
			sign1Value = (try! signingKey.signature(for: dataToSign)).rawRepresentation
		}
		return sign1Value
	}
}
