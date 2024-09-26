import Clibuv

public protocol UVAddressRepresentable {}

@inlinable
func castToBaseAddress(_ address: UnsafeMutablePointer<some UVAddressRepresentable>) -> UnsafeMutablePointer<sockaddr> {
    func castPointer(_ p: UnsafeMutableRawPointer) -> UnsafeMutablePointer<sockaddr> {
        p.assumingMemoryBound(to: sockaddr.self)
    }

    return castPointer(address)
}

@inlinable
func castFromBaseAddress<T: UVAddressRepresentable>(_ stream: UnsafeMutablePointer<sockaddr>) -> UnsafeMutablePointer<T> {
    func castPointer(_ p: UnsafeMutableRawPointer) -> UnsafeMutablePointer<T> {
        p.assumingMemoryBound(to: T.self)
    }

    return castPointer(stream)
}

extension sockaddr: UVAddressRepresentable {}
extension sockaddr_in: UVAddressRepresentable {}
extension sockaddr_in6: UVAddressRepresentable {}
