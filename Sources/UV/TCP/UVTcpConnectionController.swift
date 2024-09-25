public final class UVTcpConnectionController: @unchecked Sendable {
    let connectionId: UInt
    let serverId: UInt
    private let jobs: UVJobs

    init(jobs: UVJobs, server serverId: UInt, connection connectionId: UInt) {
        self.connectionId = connectionId
        self.serverId = serverId
        self.jobs = jobs
    }

    func read(using: @escaping (@Sendable (UVTcpBuffer) -> Void) = { _ in }, disconnect: @escaping (@Sendable () -> Void) = {}) {
        jobs.add(command: .startTcpReading(server: serverId, connection: connectionId, callback: using, disconnect: disconnect))
    }

    func write(_ data: UVTcpBuffer, using: @escaping (@Sendable () -> Void) = {}) {
        jobs.add(command: .writeTcp(server: serverId, connection: connectionId, buffer: data, callback: using))
    }

    func close() {}

    func reset() {}

    deinit {
        close()
    }
}
