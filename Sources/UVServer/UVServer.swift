import UVCore

public final actor UVServer {
    private let executor: UVExecutor
    private let thread: UVExecutionThread

    private var config: UVTcpServerSetup

    public init(address: UVIPAddress = .ipv4("127.0.0.1"), port: UInt = 8080) {
        thread = UVExecutionThread()
        thread.start()
        executor = thread.executor
        config = UVTcpServerSetup(address, port: Int32(port))
    }

    public func start(using connectionCallback: (@escaping @Sendable (Result<UVTcpConn, UVError>) -> Void) = { _ in }) async -> Result<UInt, UVError> {
        config.onConnection = { status in
            print("new message")
            switch status {
            case let .success(success):
                connectionCallback(.success(UVTcpConn(controller: success)))
            case let .failure(failure):
                connectionCallback(.failure(failure))
            }
        }

        return await withCheckedContinuation { continuation in
            config.onStart = { status in
                continuation.resume(returning: status)
            }
            guard let config = config.config else {
                return continuation.resume(returning: .failure(.failedToInit))
            }
            thread.startListening(with: config)
        }
    }

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    deinit {
        thread.cancel()
        thread.join()
    }
}

public extension UVServer {
    struct UVTcpConn: Sendable {
        private let controller: UVTcpConnectionController
        public let requests: AsyncStream<UVTcpBuffer>

        fileprivate init(controller: UVTcpConnectionController) {
            self.controller = controller
            requests = AsyncStream<UVTcpBuffer> { continuation in
                controller.read { buffer in
                    continuation.yield(buffer)
                } disconnect: {
                    continuation.finish()
                }
            }
        }

        public func write(_ buffer: UVTcpBuffer) async {
            await withCheckedContinuation { continuation in
                controller.write(buffer) {
                    continuation.resume()
                }
            }
        }

        public func close() async {
            await withCheckedContinuation { continuation in
                controller.close()
                continuation.resume()
            }
        }
    }
}
