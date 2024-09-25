import Clibuv

public typealias UVTask = @Sendable () -> Void
public typealias UVCheckTimeCallback = @Sendable (UInt64) -> Void

enum UVTaskType {
    case blocking(task: UVTask)
    case timeNow(callback: UVCheckTimeCallback)
    case scheduleBlockingOnceAfter(task: UVTask, timeout: UInt64)
    case scheduleBlockingOnceAt(task: UVTask, timeout: UInt64)
    case listenTcp(with: UVTcpServerConfig)
    case startTcpReading(server: UInt, connection: UInt, callback: @Sendable (UVTcpBuffer) -> Void, disconnect: @Sendable () -> Void)
    case closeTcpConnection(server: UInt, connection: UInt)
    case writeTcp(server: UInt, connection: UInt, buffer: UVTcpBuffer, callback: @Sendable () -> Void)
    case stopListeningTcp(server: UInt)
    case stop
}
