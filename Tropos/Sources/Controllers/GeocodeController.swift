import CoreLocation
import ReactiveCocoa

@objc(TRGeocodeController) final class GeocodeController: NSObject {
    private let geocoder = CLGeocoder()

    @objc(reverseGeocodeLocation:) func reverseGeocode(location location: CLLocation) -> RACSignal {
        return RACSignal.createSignal { [geocoder] subscriber in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                switch (placemarks?.first, error) {
                case let (placemark?, nil):
                    subscriber.sendNext(placemark)
                    subscriber.sendCompleted()
                case let (nil, error?):
                    subscriber.sendError(error)
                default:
                    subscriber.sendCompleted()
                }
            }

            return RACDisposable(block: geocoder.cancelGeocode)
        }
    }
}
