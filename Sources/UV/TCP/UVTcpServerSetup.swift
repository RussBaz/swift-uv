import Clibuv

public enum UVIPAddress {
    case ipv4(String)
    case ipv6(String)
}

public final class UVTcpServerSetup {
    public let address: UVIPAddress
    public let port: Int32
    public var onStart: (@Sendable (Result<UInt, UVError>) -> Void)?
    public var onStop: (@Sendable (UInt, UVTcpServerStatus) -> Void)?
    public var onConnection: (@Sendable (Result<UVTcpConnectionController, UVError>) -> Void)?

    public init(_ address: UVIPAddress = .ipv4("127.0.0.1"), port: Int32 = 8080) {
        self.address = address
        self.port = port
    }

    var config: UVTcpServerConfig? {
        .init(from: self)
    }
}

public struct UVTcpServerConfig {
    public let addr: sockaddr
    public let address: UVIPAddress
    public let port: Int32
    public let onStart: (@Sendable (Result<UInt, UVError>) -> Void)?
    public let onStop: (@Sendable (UInt, UVTcpServerStatus) -> Void)?
    public let onConnection: (@Sendable (Result<UVTcpConnectionController, UVError>) -> Void)?
}

extension UVTcpServerConfig {
    init?(from setup: UVTcpServerSetup) {
        var addr = sockaddr()
        switch setup.address {
        case let .ipv4(address):
            guard uv_ip4_addr(address, setup.port, castFromBaseAddress(&addr)) == 0 else { return nil }
            self.addr = addr
        case let .ipv6(address):
            guard uv_ip6_addr(address, setup.port, castFromBaseAddress(&addr)) == 0 else { return nil }
            self.addr = addr
        }

        address = setup.address
        port = setup.port
        onStop = setup.onStop
        onStart = setup.onStart
        onConnection = setup.onConnection
    }
}
