import ReactiveCocoa

extension SignalType {
    func logAll(name name: String) -> Signal<Value, Error> {
        return on(event: { print(name, $0, separator: ": ") })
    }
}
