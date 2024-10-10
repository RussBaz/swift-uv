import Clibuv

func onTcpBufferAllocate(handle _: UnsafeMutablePointer<uv_handle_t>!, size: Int, buffer: UnsafeMutablePointer<uv_buf_t>!) {
    guard size > 0 else {
        buffer!.pointee.base = nil
        buffer!.pointee.len = 0
        return
    }

    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: size)
    buffer!.pointee.base = pointer
    buffer!.pointee.len = size
}

func onTcpRead(connection: UnsafeMutablePointer<uv_stream_t>!, nread: Int, buffer: UnsafePointer<uv_buf_t>!) {
    let pointer = ConnectionRef.assume(from: connection)
    let ref = pointer.pointee
    let connection = ref.manager.pointee.getConnection(with: ref.connectionId)

    guard let connection else {
        buffer.pointee.base.deinitialize(count: buffer.pointee.len)
        buffer.pointee.base.deallocate()
        return
    }

    guard nread >= 0 else {
        // An error occured
        // EOF error
        if nread == -4095 {
            connection.onDisconnect()
        }

        connection.close()
        buffer.pointee.base.deinitialize(count: buffer.pointee.len)
        buffer.pointee.base.deallocate()
        return
    }

    let buffer = UVTcpBuffer(size: nread, buf: buffer)

    connection.read(buffer: buffer)
}

func onTcpWrite(req: UnsafeMutablePointer<uv_write_t>!, status: Int32) {
    if status != 0 {
        print("Error while writing: \(status)")
    }

    let response = req!.pointee.data.load(as: UVTcpResponse.self)

    response.finalise()
}
