import Clibuv

public typealias UVTask = @Sendable () -> Void
public typealias UVCheckTimeCallback = @Sendable (UInt64) -> Void

enum UVTaskType {
    case blocking(task: UVTask)
    case timeNow(callback: UVCheckTimeCallback)
    case scheduleBlockingOnceAfter(task: UVTask, timeout: UInt64)
    case scheduleBlockingOnceAt(task: UVTask, timeout: UInt64)
    case listenTcp(with: UVTcpServerConfig)
    case startTcpReading(server: Int, connection: Int, callback: @Sendable (UVTcpBuffer) -> Void, disconnect: @Sendable () -> Void)
    case closeTcpConnection(server: Int, connection: Int)
    case writeTcp(server: Int, connection: Int, buffer: UVTcpBuffer, callback: @Sendable () -> Void)
    case stopListeningTcp(server: Int)
    case stop
}
