import Clibuv
import Foundation

private func handleAsyncJobs(_ req: UnsafeMutablePointer<uv_async_t>?) {
    guard let req else { return }

    let baton = req.pointee.data.load(as: UVJobs.self)

    baton.handleJobs()
}

private func closeJobHandle(_ req: UnsafeMutablePointer<uv_handle_t>?) {
    guard req != nil else {
        print("having issues closing the jobs handler")
        return
    }
}

private func closeAllOpenHandlers(
    _ req: UnsafeMutablePointer<uv_handle_t>?, _: UnsafeMutableRawPointer?
) {
    guard let req else { return }
    guard uv_is_closing(req) == 0 else { return }
    let name = uv_handle_type_name(req.pointee.type).map { String(cString: $0) } ?? "no-name"
    print("open handler found - \(name)")
    uv_close(req, closeJobHandle(_:))
}

final class UVJobs {
    public private(set) var req = uv_async_t()
    let tasks = UVFIFOQueue<UVTaskType>()
    let loop: UnsafeMutablePointer<uv_loop_t>
    private var timers: UVScheduledManager?
    private var tcp: UVTcpManager?

    private let getTimeWaiter = NSCondition()

    init(loop: UnsafeMutablePointer<uv_loop_t>) {
        self.loop = loop
    }

    /// The UV Event Loop must be initialised when this method is called
    static func start(_ jobs: inout UVJobs) {
        setHandlerData(on: &jobs.req, to: &jobs)
        uv_async_init(jobs.loop, &jobs.req, handleAsyncJobs(_:))
    }

    func stop() {
        uv_close(castToBaseHandler(&req), closeJobHandle(_:))
        if let tcp {
            tcp.stop()
        }
        uv_walk(loop, closeAllOpenHandlers(_:_:), nil)
        uv_stop(loop)
    }

    func add(command: UVTaskType) {
        tasks.enqueue(command)
        uv_async_send(&req)
    }

    func set(timers delegate: UVScheduledManager) {
        guard timers == nil else { return }

        timers = delegate
    }

    func set(tcp delegate: UVTcpManager) {
        guard tcp == nil else { return }

        tcp = delegate
    }

    func handleJobs() {
        while let task = tasks.dequeue() {
            switch task {
            case let .blocking(uVTask):
                uVTask()
            case .stop:
                if let tcp {
                    tcp.stop()
                }
                stop()
            case let .timeNow(callback):
                let time = uv_now(loop)
                callback(time)
            case let .scheduleBlockingOnceAfter(task, after):
                guard let timers else {
                    print("timers delegate not set up")
                    continue
                }

                timers.submit(task, in: after)
            case let .scheduleBlockingOnceAt(task, at):
                guard let timers else {
                    print("timers delegate not set up")
                    continue
                }
                timers.submit(task, at: at)
            case let .listenTcp(config):
                guard tcp != nil else { continue }
                UVTcpManager.start(config, on: &tcp!)
            case let .startTcpReading(server, connection, callback, disconnect):
                guard let tcp else { continue }
                tcp.startReading(connection, on: server, using: callback, disconnect: disconnect)
            case let .closeTcpConnection(id):
                guard let tcp else { continue }
                tcp.close(connection: id)
            case let .writeTcp(server, connection, buffer, callback):
                guard let tcp else { continue }
                tcp.write(buffer, to: connection, on: server, using: callback)
            case let .stopListeningTcp(id):
                guard let tcp else { continue }
                tcp.close(server: id)
            }
        }
    }
}
