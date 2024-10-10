import Testing
@testable import UVCore

actor SampleTestActor {
    let executor: UVExecutor
    let thread: UVExecutionThread

    private var counter = 0

    init() {
        thread = UVExecutionThread()
        thread.start()
        executor = UVExecutor(thread: thread)
    }

    func increment() {
        counter += 1
    }

    func getCounter() -> Int {
        counter
    }

    func startListening(_ config: consuming UVTcpServerConfig?) {
        guard let config else { return }

        thread.startListening(with: config)
    }

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }
}

struct uvTests {
    @Test func executorRuns() async throws {
        let config = UVTcpServerSetup()
        config.onServerStart = { status in
            switch status {
            case .success:
                print("Server started")
            case .failure:
                print("Failed to start the server")
            }
        }

        config.onConnect = { connection in
            switch connection {
            case let .success(success):
                print("New connection: \(success)")
                success.read { buffer in
                    success.write(buffer) {
                        print("write complete YAY±+!")
                    }
                } disconnect: {
                    print("Remote server closed the connection")
                }
            case let .failure(failure):
                print("Failed connection: \(failure)")
            }
        }

        let a = SampleTestActor()
        await a.increment()
        print("Hello?")
        await a.increment()
        let v = await a.getCounter()
        await a.startListening(config.config)

        try await Task.sleep(until: .now.advanced(by: .seconds(10)))

        #expect(v == 2)
    }
}
