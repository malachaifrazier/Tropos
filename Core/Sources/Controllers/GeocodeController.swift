import CoreLocation
import ReactiveCocoa

final class GeocodeController {
    private let geocoder = CLGeocoder()

    func reverseGeocode(location location: CLLocation) -> SignalProducer<CLPlacemark, NSError> {
        return SignalProducer { [geocoder] observer, disposable in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                switch (placemarks?.first, error) {
                case let (placemark?, nil):
                    observer.sendNext(placemark)
                    observer.sendCompleted()
                case let (nil, error?):
                    observer.sendFailed(error)
                default:
                    observer.sendCompleted()
                }
            }

            disposable.addDisposable(geocoder.cancelGeocode)
        }
    }
}
