import Clibuv

protocol UVManualMemoryConvertible {
    var pointer: UnsafeMutablePointer<Self> { get }
    var rawPointer: UnsafeMutableRawPointer { get }
    static func free(_ pointer: UnsafeMutablePointer<Self>)
    static func assume(_ pointer: UnsafeMutableRawPointer) -> UnsafeMutablePointer<Self>
    static func assume(from handle: UnsafeMutablePointer<uv_handle_t>) -> UnsafeMutablePointer<Self>
    static func assume(from req: UnsafeMutablePointer<uv_stream_t>) -> UnsafeMutablePointer<Self>
}

extension UVManualMemoryConvertible {
    var pointer: UnsafeMutablePointer<Self> {
        let pointer = UnsafeMutablePointer<Self>.allocate(capacity: 1)
        pointer.initialize(to: self)
        return pointer
    }

    var rawPointer: UnsafeMutableRawPointer {
        let pointer = UnsafeMutablePointer<Self>.allocate(capacity: 1)
        pointer.initialize(to: self)
        return UnsafeMutableRawPointer(mutating: pointer)
    }

    static func free(_ pointer: UnsafeMutablePointer<Self>) {
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }

    static func assume(_ pointer: UnsafeMutableRawPointer) -> UnsafeMutablePointer<Self> {
        pointer.assumingMemoryBound(to: Self.self)
    }

    static func assume(from handle: UnsafeMutablePointer<uv_handle_t>) -> UnsafeMutablePointer<Self> {
        handle.pointee.data.assumingMemoryBound(to: Self.self)
    }

    static func assume(from handle: UnsafeMutablePointer<uv_stream_t>) -> UnsafeMutablePointer<Self> {
        handle.pointee.data.assumingMemoryBound(to: Self.self)
    }
}

extension uv_buf_t: UVManualMemoryConvertible {}
