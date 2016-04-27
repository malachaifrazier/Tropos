import ReactiveCocoa
import UIKit

#if os(iOS)
extension UIApplication {
    func rac_backgroundTask<Value, Error: ErrorType>(name name: String, producer: SignalProducer<Value, Error>) -> SignalProducer<Value, Error> {
        return SignalProducer { observer, disposable in
            var task: UIBackgroundTaskIdentifier!

            task = self.beginBackgroundTaskWithName(name) {
                observer.sendInterrupted()
                self.endBackgroundTask(task)
            }

            guard task != UIBackgroundTaskInvalid else {
                observer.sendInterrupted()
                return
            }

            disposable += producer.start { event in
                observer.action(event)

                if event.isTerminating {
                    self.endBackgroundTask(task)
                }
            }
        }
    }
}
#endif
