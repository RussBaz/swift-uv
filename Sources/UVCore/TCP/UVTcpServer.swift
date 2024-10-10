import Clibuv
import MA

public enum UVTcpServerStatus {
    case waiting
    case running
    case stopped
    case failed
}

struct ServerRef: UVManualMemoryConvertible {
    let manager: UnsafeMutablePointer<UVTcpManager>
    let serverId: Int
}

final class UVTcpServer {
    let id: Int
    let manager: UVTcpManager
    let managerPointer: UnsafeMutablePointer<UVTcpManager>

    var server: uv_tcp_t

    private var addr: sockaddr
    private let address: UVIPAddress
    private let port: UInt

    private var opened = true

    let onConnect: ((Result<UVTcpConnectionController, UVError>) -> Void)?
    let onDisconnect: ((UInt) -> Void)?
    let onStop: ((UInt, UVTcpServerStatus) -> Void)?
    var onRead: ((UVTcpBuffer) -> Void)?

    init(manager: UnsafeMutablePointer<UVTcpManager>, config: UVTcpServerConfig, id: Int) {
        self.id = id
        address = config.address
        port = UInt(config.port)
        addr = config.addr
        server = uv_tcp_t()
        self.manager = manager.pointee
        managerPointer = manager
        onConnect = config.onConnect
        onDisconnect = config.onDisconnect
        onStop = config.onServerStop

        server.data = ServerRef(manager: managerPointer, serverId: id).rawPointer
        uv_tcp_init(self.manager.jobs.loop, &server)
    }

    func start() -> Result<Void, UVError> {
        var r = uv_tcp_bind(&server, &addr, 0)

        guard r == 0 else {
            close()
            return .failure(UVError(integerLiteral: r))
        }

        r = uv_listen(castToBaseStream(&server), 256, onTcpConnect(req:status:))

        guard r == 0 else {
            close()
            return .failure(UVError(integerLiteral: r))
        }

        return .success(())
    }

    func startReading(_ connectionId: Int, using callback: ((UVTcpBuffer) -> Void)?, disconnect: (() -> Void)?) {
        guard let connection = manager.getConnection(with: connectionId) else { return }
        connection.startReading(using: callback, disconnect: disconnect)
    }

    func write(_ buffer: UVTcpBuffer, to connectionId: Int, using callback: @escaping (() -> Void)) {
        guard let connection = manager.getConnection(with: connectionId) else { return }
        connection.write(buffer: buffer, using: callback)
    }

    func close() {
        guard opened else { return }
        opened = false
        uv_close(castToBaseHandler(&server), onTcpServerClose(_:))
    }

    deinit {
        close()
    }
}
