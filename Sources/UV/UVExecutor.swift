public final class UVExecutor: SerialExecutor {
    let thread: UVExecutionThread

    public init(thread: UVExecutionThread? = nil) {
        if let thread {
            self.thread = thread
        } else {
            self.thread = UVExecutionThread()
            self.thread.start()
        }
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        thread.submitBlocking {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func stop() {
        if !thread.isCancelled {
            thread.cancel()
        }
        thread.join()
    }

    deinit {
        stop()
    }
}
