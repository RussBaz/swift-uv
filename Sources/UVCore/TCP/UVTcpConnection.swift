import Clibuv
import Collections
import Foundation
import MA

enum UVTcpConnectionStatus {
    case waiting
    case opened
    case closed
    case failed
}

struct ConnectionRef: UVManualMemoryConvertible {
    let manager: UnsafeMutablePointer<UVTcpManager>
    let serverId: Int
    let connectionId: Int
}

final class UVTcpConnection {
    let id: Int
    private let manager: UnsafeMutablePointer<UVTcpManager>
    private var connection: uv_tcp_t
    let serverId: Int
    private let server: UVTcpServer

    private var allocatedBufferIds = Deque<Int>()
    private let responseBuffers = MAContainer<UVTcpResponse>()

    private var currentResponseId: UInt = 0

    private var callback: ((UVTcpBuffer) -> Void)?
    private var disconnectCallback: (() -> Void)?

    private var opened = true

    init(id: Int, server: UVTcpServer) {
        self.id = id
        connection = uv_tcp_t()
        self.server = server
        serverId = server.id
        manager = server.managerPointer
        connection.data = ConnectionRef(manager: server.managerPointer, serverId: serverId, connectionId: id).rawPointer
        uv_tcp_init(server.manager.jobs.loop, &connection)
    }

    func accept() -> Result<Void, UVError> {
        let r = uv_accept(castToBaseStream(&server.server), castToBaseStream(&connection))
        guard r == 0 else {
            close()
            return .failure(UVError(integerLiteral: r))
        }

        return .success(())
    }

    func startReading(using callback: ((UVTcpBuffer) -> Void)?, disconnect: (() -> Void)?) {
        self.callback = callback
        disconnectCallback = disconnect
        let r = uv_read_start(castToBaseStream(&connection), onTcpBufferAllocate(handle:size:buffer:), onTcpRead(connection:nread:buffer:))

        guard r == 0 else {
            close()
            return
        }
    }

    func read(buffer: UVTcpBuffer) {
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
        let id = responseBuffers.retain { id in
            UVTcpResponse(id: id, connection: self, buffer: container) {
                self.responseBuffers.release(id)
                callback()
            }
        }!
        responseBuffers.update(with: id) { response in
            response.write(&response, to: &connection)
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
        uv_close(castToBaseHandler(&connection), onTcpDisconnect(handle:))
    }

    func removeReponseBuffer(with id: Int) {
        responseBuffers.release(id)
    }

    deinit {
        close()
    }
}
