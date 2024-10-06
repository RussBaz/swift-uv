import Clibuv

private func onWrite(req: UnsafeMutablePointer<uv_write_t>?, status: Int32) {
    guard req != nil else {
        print("having issues writing")
        return
    }

    guard status == 0 else {
        return
    }

    let response = req!.pointee.data.load(as: UVTcpResponse.self)

    response.finalise()
}

final class UVTcpResponse {
    private let id: Int
    private let callback: () -> Void
    private let connection: UVTcpConnection
    private var request = uv_write_t()
    private let buffer: UVTcpBuffer
    private var running = true

    init(id: Int, connection: UVTcpConnection, buffer: UVTcpBuffer, callback: @escaping () -> Void) {
        self.connection = connection
        self.buffer = buffer
        self.id = id
        self.callback = callback
    }

    func write(_ pointer: UnsafeMutablePointer<UVTcpResponse>) {
        setStreamData(on: &request, to: pointer)
        let status = uv_write(&request, castToBaseStream(&connection.connection), buffer.getBuffer(), 1, onWrite(req:status:))

        guard status == 0 else {
            finalise()
            return
        }
    }

    func finalise() {
        callback()
        connection.removeReponseBuffer(with: id)
    }
}
