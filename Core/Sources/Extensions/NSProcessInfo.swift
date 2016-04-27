import ReactiveCocoa

extension NSProcessInfo {
    func rac_expiringActivity<Value, Error: ErrorType>(
        reason reason: String,
        producer: SignalProducer<Value, Error>,
        timeout: NSTimeInterval = 15
    ) -> SignalProducer<Value, Error> {
        return SignalProducer { observer, disposable in
            let semaphore = dispatch_semaphore_create(0)

            NSProcessInfo.processInfo().performExpiringActivityWithReason(reason) { expired in
                if expired {
                    observer.sendInterrupted()
                    dispatch_semaphore_signal(semaphore)
                } else {
                    let dispatch_timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * NSTimeInterval(NSEC_PER_SEC)))
                    let result = dispatch_semaphore_wait(semaphore, dispatch_timeout)
                    if result != 0 {
                        observer.sendInterrupted()
                    }
                }
            }

            disposable += producer.start { event in
                observer.action(event)

                if event.isTerminating {
                    dispatch_semaphore_signal(semaphore)
                }
            }
        }
    }
}
