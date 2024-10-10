import Clibuv

final class UVTcpResponse {
    private let id: Int
    private let callback: () -> Void
    private let connection: UVTcpConnection
    private var request = uv_write_t()
    private var buffer: UVTcpBuffer
    private let _buffer: UnsafeMutablePointer<uv_buf_t>
    private var running = true

    init(id: Int, connection: UVTcpConnection, buffer: UVTcpBuffer, callback: @escaping () -> Void) {
        self.connection = connection
        self.buffer = buffer
        _buffer = UnsafeMutablePointer(buffer.buffer.pointer)
        self.id = id
        self.callback = callback
    }

    func write(
        _ pointer: UnsafeMutablePointer<UVTcpResponse>,
        to connection: UnsafeMutablePointer<uv_tcp_t>
    ) {
        setStreamData(on: &request, to: pointer)
        let status = uv_write(
            &request, castToBaseStream(connection), _buffer, 1, onTcpWrite(req:status:)
        )

        guard status == 0 else {
            finalise()
            return
        }
    }

    func finalise() {
        uv_buf_t.free(_buffer)
        callback()
    }
}
