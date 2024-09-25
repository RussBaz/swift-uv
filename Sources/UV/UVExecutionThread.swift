import Clibuv
import Dispatch
import Foundation

public final class UVExecutionThread: Thread, @unchecked Sendable {
    private var loop: uv_loop_t
    private var jobs: UVJobs
    private var running = NSLock()
    private var _executor: UVExecutor?

    override public init() {
        loop = uv_loop_t()
        uv_loop_init(&loop)
        jobs = UVJobs(loop: &loop)
        jobs.set(timers: UVScheduledManager(jobs))
        jobs.set(tcp: UVTcpManager(jobs: jobs))
        UVJobs.start(&jobs)
        super.init()
    }

    deinit {
        var counter = 0
        while true {
            counter += 1
            let result = uv_loop_close(&loop)

            if result == 0 { break }
            let name = uv_err_name(result).map { String(cString: $0) }
            let description = uv_strerror(result).map { String(cString: $0) }

            let message = if let name {
                if let description {
                    "[\(name): \(description)]"
                } else {
                    "[\(name)]"
                }
            } else {
                "[unknown code]"
            }

            print("Error: \(result) \(message)")

            guard counter < 15 else { fatalError("Could not deinit the uv_loop") }
        }
    }

    override public func main() {
        running.lock()
        defer { running.unlock() }
        while true {
            guard !isCancelled else { break }
            print("starting the loop on thread: \(self)")
            uv_run(&loop, UV_RUN_DEFAULT)
            print("the loop on thread: \(self) stopped")
        }
    }

    override public func cancel() {
        super.cancel()
        jobs.add(command: .stop)
    }

    public func join() {
        running.lock()
        running.unlock()
    }

    public func submitBlocking(task: @escaping UVTask) {
        jobs.add(command: .blocking(task: task))
    }

    public func submitBlocking(task: @escaping UVTask, after timeout: UInt64) {
        jobs.add(command: .scheduleBlockingOnceAfter(task: task, timeout: timeout))
    }

    public func submitBlocking(task: @escaping UVTask, at timeout: UInt64) {
        jobs.add(command: .scheduleBlockingOnceAt(task: task, timeout: timeout))
    }

    public func startListening(with setup: UVTcpServerConfig) {
        jobs.add(command: .listenTcp(with: setup))
    }

    public var executor: UVExecutor {
        if let _executor {
            return _executor
        } else {
            _executor = UVExecutor(thread: self)
            return _executor!
        }
    }
}
