import Foundation

import Clibuv

public final class UVTcpBuffer: @unchecked Sendable {
    private let size: UInt32
    private(set) var data: UnsafeMutablePointer<CChar>
    private var _data: ContiguousArray<CChar>?
    private var buffer: uv_buf_t?
    private var mustDeallocate = true

    init(size: Int) {
        guard size > 0 else { fatalError("Zero or less buffer?") }
        self.size = UInt32(size)
        data = .allocate(capacity: size)
        data.initialize(to: 0)
    }

    public init?(string: String) {
        guard !string.isEmpty else {
            data = .allocate(capacity: 1)
            size = 1
            data.initialize(to: 0)
            return
        }
        _data = string.utf8CString

        let (pointer, count) = _data!.withUnsafeBufferPointer { pointer in
            (pointer.baseAddress, UInt32(pointer.count))
        }
        guard let pointer else { return nil }
        mustDeallocate = false
        data = UnsafeMutablePointer(mutating: pointer)
        size = count
    }

    func allocate(to buffer: UnsafeMutablePointer<uv_buf_t>) {
        buffer.pointee.base = data
        #if os(Windows)
            buffer.pointee.len = size
        #else
            buffer.pointee.len = Int(size)
        #endif
    }

    func getBuffer() -> UnsafeMutablePointer<uv_buf_t> {
        if buffer == nil {
            #if os(Windows)
                buffer = uv_buf_t(len: size, base: data)
            #else
                buffer = uv_buf_t(base: data, len: Int(size))
            #endif
        }

        return withUnsafeMutablePointer(to: &buffer!) { $0 }
    }

    public var asString: String {
        String(cString: data)
    }

    deinit {
        guard mustDeallocate else { return }
        data.deallocate()
    }
}
