import Clibuv
import MA

public final class UVTcpManager {
    let jobs: UVJobs
    private let servers = MAContainer<UVTcpServer>()
    private let connections = MAContainer<UVTcpConnection>(initialSize: 256)

    init(jobs: UVJobs) {
        self.jobs = jobs
    }

    static func start(_ config: UVTcpServerConfig, on manager: inout UVTcpManager) {
        let id = manager.servers.retain { id in
            UVTcpServer(manager: &manager, config: config, id: id)
        }

        guard let id else { return }

        let r = manager.servers.update(with: id) { server in
            server.start()
        }

        switch r {
        case .success:
            if let onStart = config.onServerStart {
                onStart(.success(id))
            }
        case let .failure(failure):
            manager.servers.release(id)
            if let onStart = config.onServerStart {
                onStart(.failure(failure))
            }
        case .none:
            manager.servers.release(id)
            if let onStart = config.onServerStart {
                onStart(.failure(.failedToInit))
            }
        }
    }

    func getPointerToConnection(with id: Int) -> UnsafeMutablePointer<UVTcpConnection>? {
        connections.pointer(to: id)
    }

    func getServer(with id: Int) -> UVTcpServer? {
        servers.find(by: id)
    }

    func getConnection(with id: Int) -> UVTcpConnection? {
        connections.find(by: id)
    }

    func connect(status: Int32, server id: Int) {
        guard status == 0 else { return }
        guard let server = getServer(with: id) else { return }

        let id = connections.retain {
            UVTcpConnection(id: $0, server: server)
        }!
        let pointer = connections.pointer(to: id)!
        let r = pointer.pointee.accept()

        switch r {
        case .success:
            if let onConnect = server.onConnect {
                onConnect(
                    .success(
                        UVTcpConnectionController(jobs: jobs, server: server.id, connection: id)))
            }
        case let .failure(failure):
            connections.release(id)
            if let onConnect = server.onConnect {
                onConnect(.failure(failure))
            }
        }
    }

    func startReading(
        _ connectionId: Int, on serverId: Int, using callback: ((UVTcpBuffer) -> Void)?,
        disconnect: (() -> Void)?
    ) {
        guard let server = getServer(with: serverId) else { return }
        server.startReading(connectionId, using: callback, disconnect: disconnect)
    }

    func stopReading(_: Int, on _: Int) {}

    func write(
        _ buffer: UVTcpBuffer, to connectionId: Int, on serverId: Int,
        using callback: @escaping (() -> Void)
    ) {
        guard let server = getServer(with: serverId) else { return }
        server.write(buffer, to: connectionId, using: callback)
    }

    func stop() {}

    func close(connection id: Int) {
        connections.release(id)
    }

    func close(server id: Int) {
        servers.release(id)
    }
}
