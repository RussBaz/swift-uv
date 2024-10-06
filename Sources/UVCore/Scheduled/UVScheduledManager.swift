import Clibuv
import Foundation
import MA

private func handleScheduledJob(_ req: UnsafeMutablePointer<uv_timer_t>?) {
    guard let req else { return }
    let timer = req.pointee.data.load(as: UVTimer.self)
    timer.run()
}

private func closeScheduledJob(_ req: UnsafeMutablePointer<uv_handle_t>?) {
    guard let req else {
        print("Having issues closing the jobs handler")
        return
    }

    let timer = req.pointee.data.load(as: UVTimer.self)
    timer.delete()
}

final class UVScheduledManager {
    private let jobs: UVJobs
    private let timers = MAContainer<UVTimer>()

    init(_ jobs: UVJobs) {
        self.jobs = jobs
    }

    /// Schedule a task to run after a 'timeout' in milliseconds
    func submit(_ task: @escaping UVTask, in timeout: UInt64) {
        let id = timers.retain { id in
            UVTimer(manager: self, timeout: timeout, id: id, task: task)
        }
        guard let id else { return }

        timers.update(with: id) { timer in
            UVTimer.start(&timer, on: jobs.loop)
        }
    }

    /// Schedule a task to run once the loop timer passes a 'timeout' in milliseconds
    func submit(_ task: @escaping UVTask, at timeout: UInt64) {
        let time = uv_now(jobs.loop)
        if timeout > time {
            submit(task, in: timeout - time)
        } else {
            submit(task, in: 0)
        }
    }

    func removeTimer(with id: Int) {
        timers.release(id)
    }

    func timeNow(callback: @escaping UVCheckTimeCallback) {
        let time = uv_now(jobs.loop)
        callback(time)
    }
}

private final class UVTimer {
    private let id: Int
    private var value: uv_timer_t
    private var manager: UVScheduledManager
    private let task: UVTask
    private let timeout: UInt64

    init(manager: UVScheduledManager, timeout: UInt64, id: Int, task: @escaping UVTask) {
        value = uv_timer_t()
        self.manager = manager
        self.task = task
        self.timeout = timeout
        self.id = id
    }

    func run() {
        task()
        stop()
    }

    func stop() {
        uv_timer_stop(&value)
        uv_close(castToBaseHandler(&value), closeScheduledJob(_:))
    }

    fileprivate func delete() {
        manager.removeTimer(with: id)
    }

    static func start(_ timer: inout UVTimer, on loop: UnsafeMutablePointer<uv_loop_t>) {
        uv_timer_init(loop, &timer.value)
        setHandlerData(on: &timer.value, to: &timer)
        uv_timer_start(&timer.value, handleScheduledJob(_:), timer.timeout, 0)
    }
}
