import Clibuv

public protocol UVHandlerRepresentable {}

@inlinable
func castToBaseHandler(_ handler: UnsafeMutablePointer<some UVHandlerRepresentable>) -> UnsafeMutablePointer<uv_handle_t> {
    func castPointer(_ p: UnsafeMutableRawPointer) -> UnsafeMutablePointer<uv_handle_t> {
        p.assumingMemoryBound(to: uv_handle_t.self)
    }

    return castPointer(handler)
}

@inlinable
func setHandlerData(on handler: UnsafeMutablePointer<some UVHandlerRepresentable>, to data: UnsafeMutablePointer<some AnyObject>) {
    let handler = castToBaseHandler(handler)

    func set(data: UnsafeMutableRawPointer) {
        handler.pointee.data = data
    }

    set(data: data)
}

extension uv_handle_t: UVHandlerRepresentable {}
extension uv_async_t: UVHandlerRepresentable {}
extension uv_timer_t: UVHandlerRepresentable {}
extension uv_tcp_t: UVHandlerRepresentable {}
