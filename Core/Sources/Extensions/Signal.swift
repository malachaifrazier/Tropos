import ReactiveCocoa

extension SignalType {
    func completeOnInterrupted() -> Signal<Value, Error> {
        return materialize()
            .map { event -> Event<Value, Error> in
                if case .Interrupted = event {
                    return .Completed
                } else {
                    return event
                }
            }
            .dematerialize()
    }

    func logAll(name name: String) -> Signal<Value, Error> {
        return on(event: { print(name, $0, separator: ": ") })
    }
}
