import ReactiveCocoa
import Result

extension SignalProducerType {
    func logAll(name name: String) -> SignalProducer<Value, Error> {
        return lift {
            $0.logAll(name: name)
        }.on(started: {
            print(name, $0, separator: ": ")
        })
    }

    /// Merges a sequence of producers, returning a new signal producer
    /// that passes through all values from each producer, until the
    /// first inner producer terminates.
    static func unify<Producers: SequenceType where Producers.Generator.Element == SignalProducer<Value, Error>>(
        producers producers: Producers
    ) -> SignalProducer<Value, Error> {
        return SignalProducer(values: producers.lazy.map { $0.materialize() })
            .flatten(.Merge)
            .dematerialize()
    }
}
