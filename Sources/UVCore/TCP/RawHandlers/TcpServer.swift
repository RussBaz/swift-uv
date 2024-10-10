import Clibuv

func onTcpServerClose(_ handle: UnsafeMutablePointer<uv_handle_t>!) {
    let pointer = ServerRef.assume(from: handle!)
    let manager = pointer.pointee.manager.pointee
    manager.close(server: pointer.pointee.serverId)
    ServerRef.free(pointer)
}
