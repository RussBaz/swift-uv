import Clibuv

public protocol UVStreamRepresentable {}

@inlinable
func castFromBaseStream<T: UVStreamRepresentable>(_ stream: UnsafeMutablePointer<uv_stream_t>)
    -> UnsafeMutablePointer<T>
{
    func castPointer(_ p: UnsafeMutableRawPointer) -> UnsafeMutablePointer<T> {
        p.assumingMemoryBound(to: T.self)
    }

    return castPointer(stream)
}

@inlinable
func castToBaseStream(_ stream: UnsafeMutablePointer<some UVStreamRepresentable>)
    -> UnsafeMutablePointer<uv_stream_t>
{
    func castPointer(_ p: UnsafeMutableRawPointer) -> UnsafeMutablePointer<uv_stream_t> {
        p.assumingMemoryBound(to: uv_stream_t.self)
    }

    return castPointer(stream)
}

@inlinable
func setStreamData(
    on stream: UnsafeMutablePointer<some UVStreamRepresentable>,
    to data: UnsafeMutablePointer<some AnyObject>
) {
    let stream = castToBaseStream(stream)

    stream.pointee.data = UnsafeMutableRawPointer(data)
}

extension uv_stream_t: UVStreamRepresentable {}
extension uv_tcp_t: UVStreamRepresentable {}
extension uv_write_t: UVStreamRepresentable {}
