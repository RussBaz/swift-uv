import Clibuv

public protocol UVRequestRepresentable {}

@inlinable
func castToBaseRequest(_ handler: UnsafeMutablePointer<some UVRequestRepresentable>) -> UnsafeMutablePointer<uv_req_t> {
    func castPointer(_ p: UnsafeMutableRawPointer) -> UnsafeMutablePointer<uv_req_t> {
        p.assumingMemoryBound(to: uv_req_t.self)
    }

    return castPointer(handler)
}

extension uv_req_t: UVRequestRepresentable {}
extension uv_work_t: UVRequestRepresentable {}
extension uv_shutdown_t: UVRequestRepresentable {}
