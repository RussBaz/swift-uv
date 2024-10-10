import Clibuv

func onTcpConnect(req: UnsafeMutablePointer<uv_stream_t>!, status: Int32) {
    let pointer = ServerRef.assume(from: req!)
    let manager = pointer.pointee.manager.pointee
    manager.connect(status: status, server: pointer.pointee.serverId)
}

func onTcpDisconnect(handle: UnsafeMutablePointer<uv_handle_t>!) {
    let pointer = ConnectionRef.assume(from: handle!)
    pointer.pointee.manager.pointee.close(connection: pointer.pointee.connectionId)
    ConnectionRef.free(pointer)
}
