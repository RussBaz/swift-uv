public final class UVTcpConnectionController: @unchecked Sendable {
    let connectionId: UInt
    let serverId: UInt
    private let jobs: UVJobs

    init(jobs: UVJobs, server serverId: UInt, connection connectionId: UInt) {
        self.connectionId = connectionId
        self.serverId = serverId
        self.jobs = jobs
    }

    public func read(using: @escaping (@Sendable (UVTcpBuffer) -> Void) = { _ in }, disconnect: @escaping (@Sendable () -> Void) = {}) {
        jobs.add(command: .startTcpReading(server: serverId, connection: connectionId, callback: using, disconnect: disconnect))
    }

    public func write(_ data: UVTcpBuffer, using: @escaping (@Sendable () -> Void) = {}) {
        jobs.add(command: .writeTcp(server: serverId, connection: connectionId, buffer: data, callback: using))
    }

    public func close() {
        jobs.add(command: .closeTcpConnection(server: serverId, connection: connectionId))
    }

    public func reset() {}

    deinit {
        close()
    }
}
