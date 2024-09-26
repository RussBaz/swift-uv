import Clibuv

final class UVTcpManager {
    struct Item {
        let id: UInt
        var value: UVTcpServer
    }

    let jobs: UVJobs
    private let servers = UVIdArray<UVTcpServer>()

    init(jobs: UVJobs) {
        self.jobs = jobs
    }

    func start(_ config: UVTcpServerConfig) {
        servers.append { id in
            UVTcpServer(manager: self, config: config, id: id)
        }

        let id = servers.currentId

        let r = servers.update(with: id) { server in
            server.start(&server)
        }

        switch r {
        case .success:
            if let onStart = config.onStart {
                onStart(.success(id))
            }
        case let .failure(failure):
            servers.remove(with: id)
            if let onStart = config.onStart {
                onStart(.failure(failure))
            }
        case .none:
            servers.remove(with: id)
            if let onStart = config.onStart {
                onStart(.failure(.failedToInit))
            }
        }
    }

    func getServer(with id: UInt) -> UVTcpServer? {
        servers.find(by: id)
    }

    func startReading(_ connectionId: UInt, on serverId: UInt, using callback: ((UVTcpBuffer) -> Void)?, disconnect: (() -> Void)?) {
        guard let server = getServer(with: serverId) else { return }
        server.startReading(connectionId, using: callback, disconnect: disconnect)
    }

    func write(_ buffer: UVTcpBuffer, to connectionId: UInt, on serverId: UInt, using callback: @escaping (() -> Void)) {
        guard let server = getServer(with: serverId) else { return }
        server.write(buffer, to: connectionId, using: callback)
    }

    func stop() {}

    func closeConnection(_ connectionId: UInt, on serverId: UInt) {
        guard let server = getServer(with: serverId) else { return }
        guard let connection = server.getConnection(with: connectionId) else { return }
        connection.close()
    }

    func close(_ id: UInt) {
        guard let server = getServer(with: id) else { return }
        server.close()
    }
}
