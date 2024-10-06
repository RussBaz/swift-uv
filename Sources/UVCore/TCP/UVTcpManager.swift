import Clibuv
import MA

final class UVTcpManager {
    struct Item {
        let id: UInt
        var value: UVTcpServer
    }

    let jobs: UVJobs
    private let servers = MAContainer<UVTcpServer>()

    init(jobs: UVJobs) {
        self.jobs = jobs
    }

    func start(_ config: UVTcpServerConfig) {
        let id = servers.retain { id in
            UVTcpServer(manager: self, config: config, id: id)
        }

        guard let id else { return }

        let r = servers.update(with: id) { server in
            server.start(&server)
        }

        switch r {
        case .success:
            if let onStart = config.onStart {
                onStart(.success(id))
            }
        case let .failure(failure):
            servers.release(id)
            if let onStart = config.onStart {
                onStart(.failure(failure))
            }
        case .none:
            servers.release(id)
            if let onStart = config.onStart {
                onStart(.failure(.failedToInit))
            }
        }
    }

    func getServer(with id: Int) -> UVTcpServer? {
        servers.find(by: id)
    }

    func startReading(_ connectionId: Int, on serverId: Int, using callback: ((UVTcpBuffer) -> Void)?, disconnect: (() -> Void)?) {
        guard let server = getServer(with: serverId) else { return }
        server.startReading(connectionId, using: callback, disconnect: disconnect)
    }

    func write(_ buffer: UVTcpBuffer, to connectionId: Int, on serverId: Int, using callback: @escaping (() -> Void)) {
        guard let server = getServer(with: serverId) else { return }
        server.write(buffer, to: connectionId, using: callback)
    }

    func stop() {}

    func closeConnection(_ connectionId: Int, on serverId: Int) {
        guard let server = getServer(with: serverId) else { return }
        guard let connection = server.getConnection(with: connectionId) else { return }
        connection.close()
    }

    func close(_ id: Int) {
        guard let server = getServer(with: id) else { return }
        server.close()
    }
}
