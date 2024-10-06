import Clibuv
import Collections
import Foundation
import MA

private func onBufferAllocate(handle: UnsafeMutablePointer<uv_handle_t>?, size: Int, buffer: UnsafeMutablePointer<uv_buf_t>?) {
    guard handle != nil, buffer != nil else {
        print("problem allocating tcp connection buffer")
        return
    }

    let connection = handle!.pointee.data.load(as: UVTcpConnection.self)

    let emptyBuffer = connection.allocateBuffer(size: size)

    emptyBuffer.allocate(to: buffer!)
}

private func onRead(connection: UnsafeMutablePointer<uv_stream_t>?, nread: Int, buffer: UnsafePointer<uv_buf_t>?) {
    guard connection != nil, buffer != nil else {
        print("problem reading tcp connection buffer")
        return
    }

    let connection = connection!.pointee.data.load(as: UVTcpConnection.self)

    guard nread >= 0 else {
        // An error occured
        if nread == -4095 {
            connection.onDisconnect()
        }

        connection.close()
        return
    }

    guard nread > 0 else {
        // The stream is empty
        connection.onDisconnect()
        connection.close()
        return
    }

    connection.read()
}

enum UVTcpConnectionStatus {
    case waiting
    case opened
    case closed
    case failed
}

final class UVTcpConnection {
    var connection: uv_tcp_t
    private let server: UVTcpServer

    private var allocatedBufferIds = Deque<Int>()
    private let inBuffers = MAContainer<UVTcpBuffer>()
    private let outBuffers = MAContainer<UVTcpResponse>()

    private var currentResponseId: UInt = 0

    private var callback: ((UVTcpBuffer) -> Void)?
    private var disconnectCallback: (() -> Void)?

    private var opened = true

    init(server: UVTcpServer) {
        connection = uv_tcp_t()
        self.server = server
        uv_tcp_init(server.manager.jobs.loop, &connection)
    }

    func accept(_ pointer: UnsafeMutablePointer<UVTcpConnection>) -> Result<Void, UVError> {
        setStreamData(on: &connection, to: pointer)

        let r = uv_accept(castToBaseStream(&server.server), castToBaseStream(&connection))
        guard r == 0 else {
            close()
            return .failure(UVError(integerLiteral: r))
        }

        return .success(())
    }

    func allocateBuffer(size: Int) -> UVTcpBuffer {
        let id = inBuffers.retain(UVTcpBuffer(size: size))!
        allocatedBufferIds.append(id)

        return inBuffers.find(by: id)!
    }

    func startReading(using callback: ((UVTcpBuffer) -> Void)?, disconnect: (() -> Void)?) {
        self.callback = callback
        disconnectCallback = disconnect
        let r = uv_read_start(castToBaseStream(&connection), onBufferAllocate(handle:size:buffer:), onRead(connection:nread:buffer:))

        guard r == 0 else {
            close()
            return
        }
    }

    func read() {
        guard let id = allocatedBufferIds.popFirst() else { return }
        guard let buffer = inBuffers.find(by: id) else { return }

        if let callback {
            callback(buffer)
        }
    }

    func stopReading() {
        callback = nil
        disconnectCallback = nil
        uv_read_stop(castToBaseStream(&connection))
    }

    func write(buffer container: UVTcpBuffer, using callback: @escaping (() -> Void)) {
        let id = outBuffers.retain {
            UVTcpResponse(id: $0, connection: self, buffer: container, callback: callback)
        }!
        outBuffers.update(with: id) { response in
            response.write(&response)
        }
    }

    func onDisconnect() {
        if let disconnectCallback {
            disconnectCallback()
        }
    }

    func reset() {}

    func close() {
        guard opened else { return }
        opened = false
        uv_close(castToBaseHandler(&connection), nil)
    }

    func removeReponseBuffer(with id: Int) {
        outBuffers.release(id)
    }

    deinit {
        close()
    }
}
