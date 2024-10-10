import Clibuv
import Foundation

public final class UVTcpBuffer: @unchecked Sendable {
    private let size: UInt32
    private let _buffer: UnsafeMutableRawBufferPointer?
    private var _data: ContiguousArray<CChar>?

    private var mustDeallocate = true
    private var nextReadStart = 0

    init(size: Int, buf: UnsafePointer<uv_buf_t>) {
        self.size = UInt32(size)
        _buffer = UnsafeMutableRawBufferPointer(start: buf.pointee.base, count: Int(buf.pointee.len))
    }

    public init(string: String) {
        let string = string.utf8CString
        let count = UInt32(string.count - 1)

        mustDeallocate = false

        guard count > 0 else {
            size = 0
            _buffer = nil
            return
        }

        _data = string
        size = count
        _buffer = _data!.withUnsafeMutableBufferPointer { ptr in
            UnsafeMutableRawBufferPointer(ptr)
        }
    }

    func read(next bytes: Int) -> UVTcpBufferIterator {
        defer { nextReadStart += bytes }
        return UVTcpBufferIterator(buffer: _buffer, start: nextReadStart, read: bytes)
    }

    var buffer: uv_buf_t {
        if let _buffer {
            _buffer.withMemoryRebound(to: CChar.self) { ptr in
                #if os(Windows)
                    uv_buf_t(len: Swift.max(Swift.min(UInt32(ptr.count), UInt32(size)), 0), base: ptr.baseAddress)
                #else
                    uv_buf_t(base: ptr.baseAddress, len: Swift.max(Swift.min(ptr.count, Int(size)), 0))
                #endif
            }
        } else {
            uv_buf_t()
        }
    }

    deinit {
        guard mustDeallocate else { return }

        if let _buffer {
            _buffer.deallocate()
        }
    }
}

public extension UVTcpBuffer {
    final class UVTcpBufferIterator: IteratorProtocol {
        private let maxSize: Int
        private let buffer: UnsafeMutableRawBufferPointer?
        private var pos: Int
        private var _next: () -> UInt8? = { nil }

        init(buffer: UnsafeMutableRawBufferPointer?, start pos: Int, read count: Int) {
            self.pos = pos
            self.buffer = buffer
            maxSize = Swift.max(Swift.min(count, buffer?.count ?? 0), 0)
            if buffer != nil {
                _next = normalNext
            }
        }

        private func normalNext() -> UInt8? {
            guard pos < maxSize else { return nil }
            defer { pos += 1 }
            return buffer!.load(fromByteOffset: pos, as: UInt8.self)
        }

        public func next() -> UInt8? {
            _next()
        }
    }
}

extension UVTcpBuffer: Sequence {
    public func makeIterator() -> UVTcpBufferIterator {
        UVTcpBufferIterator(buffer: _buffer, start: 0, read: Int(size))
    }
}
