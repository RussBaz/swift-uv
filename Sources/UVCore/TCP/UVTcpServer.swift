import Clibuv

private func onTcpServerClose(_ handle: UnsafeMutablePointer<uv_handle_t>?) {
    guard handle != nil else {
        print("having issues closing the server handler")
        return
    }

    _ = handle!.pointee.data.load(as: UVTcpServer.self)
}

private func onConnection(req: UnsafeMutablePointer<uv_stream_t>?, status: Int32) {
    guard req != nil else {
        print("having issues opening a new connection")
        return
    }

    let server = req!.pointee.data.load(as: UVTcpServer.self)

    server.newConnection(status: status)
}

public enum UVTcpServerStatus {
    case waiting
    case running
    case stopped
    case failed
}

final class UVTcpServer {
    struct Item {
        let id: UInt
        var value: UVTcpConnection
    }

    let id: UInt
    let manager: UVTcpManager
    var server: uv_tcp_t

    private var addr: sockaddr
    private let address: UVIPAddress
    private let port: UInt

    private let connections = UVIdArray<UVTcpConnection>()

    private var opened = true

    let onConnection: ((Result<UVTcpConnectionController, UVError>) -> Void)?
    let onStop: ((UInt, UVTcpServerStatus) -> Void)?
    var onRead: ((UVTcpBuffer) -> Void)?

    init(manager: UVTcpManager, config: UVTcpServerConfig, id: UInt) {
        self.id = id
        address = config.address
        port = UInt(config.port)
        addr = config.addr
        server = uv_tcp_t()
        self.manager = manager

        onConnection = config.onConnection
        onStop = config.onStop

        uv_tcp_init(manager.jobs.loop, &server)
    }

    func start(_ pointerToSelf: UnsafeMutablePointer<UVTcpServer>) -> Result<Void, UVError> {
        setStreamData(on: &server, to: pointerToSelf)

        return bind()
    }

    func bind() -> Result<Void, UVError> {
        var r = uv_tcp_bind(&server, &addr, 0)

        guard r == 0 else {
            close()
            return .failure(UVError(integerLiteral: r))
        }

        r = uv_listen(castToBaseStream(&server), 256, onConnection(req:status:))

        guard r == 0 else {
            close()
            return .failure(UVError(integerLiteral: r))
        }

        return .success(())
    }

    func newConnection(status: Int32) {
        guard status == 0 else {
            close()
            return
        }

        let connection = UVTcpConnection(server: self)
        let pointer = connections.append(connection)
        let r = connection.accept(pointer)
        let id = connections.currentId

        switch r {
        case .success:
            if let onConnection {
                onConnection(.success(UVTcpConnectionController(jobs: manager.jobs, server: self.id, connection: id)))
            }
        case let .failure(failure):
            connections.remove(with: id)
            if let onConnection {
                onConnection(.failure(failure))
            }
        }
    }

    func startReading(_ connectionId: UInt, using callback: ((UVTcpBuffer) -> Void)?, disconnect: (() -> Void)?) {
        guard let connection = getConnection(with: connectionId) else { return }
        connection.startReading(using: callback, disconnect: disconnect)
    }

    func write(_ buffer: UVTcpBuffer, to connectionId: UInt, using callback: @escaping (() -> Void)) {
        guard let connection = getConnection(with: connectionId) else { return }
        connection.write(buffer: buffer, using: callback)
    }

    func close() {
        guard opened else { return }
        uv_close(castToBaseHandler(&server), onTcpServerClose(_:))
        opened = false
    }

    func getConnection(with id: UInt) -> UVTcpConnection? {
        connections.find(by: id)
    }

    deinit {
        close()
    }
}
