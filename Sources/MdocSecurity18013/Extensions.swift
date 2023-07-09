import Foundation

extension UInt32 {
  public var data: Data {
    var int = self
    return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
  }
  
  public var byteArrayLittleEndian: [UInt8] {
    return [
      UInt8((self & 0xFF000000) >> 24),
      UInt8((self & 0x00FF0000) >> 16),
      UInt8((self & 0x0000FF00) >> 8),
      UInt8(self & 0x000000FF)
    ]
  }
}