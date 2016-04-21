import CoreLocation

private let maximumElapsedTime: NSTimeInterval = 5

extension CLLocation {
    var isStale: Bool {
        return elapsedTimeInterval > maximumElapsedTime
    }

    var elapsedTimeInterval: NSTimeInterval {
        return NSDate().timeIntervalSinceDate(timestamp)
    }
}
