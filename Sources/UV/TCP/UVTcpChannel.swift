public protocol UVTcpChannel: Actor {
    func accept(_ connection: UVTcpConnectionController)
}
