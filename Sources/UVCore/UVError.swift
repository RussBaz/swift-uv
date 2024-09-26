public enum UVError: Error {
    case UV__EOF
    case unknown(Int32)
    case notRunning
    case failedToInit
    case connectionRefused
    case serverNotFound
    case connectionNotFound
}

extension UVError {
    init(_ value: Int32) {
        self.init(integerLiteral: value)
    }

    var code: Int32 {
        switch self {
        case .UV__EOF:
            -4095
        case let .unknown(data):
            data
        case .notRunning:
            1
        case .failedToInit:
            2
        case .connectionRefused:
            3
        case .serverNotFound:
            4
        case .connectionNotFound:
            5
        }
    }
}

extension UVError: Equatable {}
extension UVError: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int32) {
        switch value {
        case -4095: self = .UV__EOF
        case 1: self = .notRunning
        case 2: self = .failedToInit
        case 3: self = .connectionRefused
        case 4: self = .serverNotFound
        case 5: self = .connectionNotFound
        default: self = .unknown(value)
        }
    }
}

extension Int32 {
    var asUVError: UVError {
        UVError(integerLiteral: self)
    }
}
