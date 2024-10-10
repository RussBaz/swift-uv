import Clibuv

public protocol UVHandlerRepresentable {}

@inlinable
func castToBaseHandler(_ handler: UnsafeMutablePointer<some UVHandlerRepresentable>)
    -> UnsafeMutablePointer<uv_handle_t>
{
    UnsafeMutableRawPointer(mutating: handler).assumingMemoryBound(to: uv_handle_t.self)
}

@inlinable
func setHandlerData(
    on handler: UnsafeMutablePointer<some UVHandlerRepresentable>,
    to data: UnsafeMutablePointer<some AnyObject>
) {
    castToBaseHandler(handler).pointee.data = UnsafeMutableRawPointer(mutating: data)
}

extension uv_handle_t: UVHandlerRepresentable {}
extension uv_async_t: UVHandlerRepresentable {}
extension uv_timer_t: UVHandlerRepresentable {}
extension uv_tcp_t: UVHandlerRepresentable {}
