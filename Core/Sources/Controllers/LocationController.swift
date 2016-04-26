import CoreLocation
import ReactiveCocoa
import Result

@objc(TRLocationController) public final class LocationController: NSObject, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager

    public override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public var requestAlwaysAuthorization: SignalProducer<Bool, NoError> {
        return SignalProducer { observer, disposable in
            if self.needsAuthorization {
                self.locationManager.requestAlwaysAuthorization()
                disposable += self.didAuthorize.start(observer)
            } else {
                disposable += self.authorized.start(observer)
            }
        }
    }

    public var requestLocation: SignalProducer<CLLocation, NSError> {
        let currentLocationUpdated: SignalProducer<CLLocation, NSError> = didUpdateLocations
            .promoteErrors(NSError.self)
            .take(1)
            .flatMap(.Concat, transform: SignalProducer.init(values:))

        let locationUpdateFailed: SignalProducer<CLLocation, NSError> = didFailWithError
            .promoteErrors(NSError.self)
            .flatMap(.Latest, transform: SignalProducer.init(error:))

        return SignalProducer.unify(producers: [currentLocationUpdated, locationUpdateFailed])
            .takeLast(1)
            .on(started: locationManager.requestLocation)
    }

    public func authorizationStatusEqualTo(status: CLAuthorizationStatus) -> Bool {
        return CLLocationManager.authorizationStatus() == status
    }
}

private extension LocationController {
    var needsAuthorization: Bool {
        return authorizationStatusEqualTo(.NotDetermined)
    }

    var didAuthorize: SignalProducer<Bool, NoError> {
        return didChangeAuthorizationStatus
            .flatMap(.Concat) { status -> SignalProducer<Bool, NoError> in
                switch status {
                case .AuthorizedWhenInUse, .AuthorizedAlways:
                    return SignalProducer(value: true)
                case .NotDetermined:
                    return .empty
                case .Denied, .Restricted:
                    return SignalProducer(value: false)
                }
            }
            .take(1)
    }

    var authorized: SignalProducer<Bool, NoError> {
        return SignalProducer { observer, _ in
            let authorized = self.authorizationStatusEqualTo(.AuthorizedWhenInUse) || self.authorizationStatusEqualTo(.AuthorizedAlways)
            observer.sendNext(authorized)
            observer.sendCompleted()
        }
    }

    var didUpdateLocations: SignalProducer<[CLLocation], NoError> {
        let selector = #selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:))
        return rac_signalForSelector(selector)
            .toSignalProducer()
            .flatMapError { _ in .empty }
            .map {
                ($0 as! RACTuple).second as! [CLLocation]
            }
    }

    var didFailWithError: SignalProducer<NSError, NoError> {
        let selector = #selector(CLLocationManagerDelegate.locationManager(_:didFailWithError:))
        return rac_signalForSelector(selector)
            .toSignalProducer()
            .flatMapError { _ in .empty }
            .map {
                ($0 as! RACTuple).second as! NSError
            }
    }

    var didChangeAuthorizationStatus: SignalProducer<CLAuthorizationStatus, NoError> {
        let selector = #selector(CLLocationManagerDelegate.locationManager(_:didChangeAuthorizationStatus:))
        return rac_signalForSelector(selector, fromProtocol: CLLocationManagerDelegate.self)
            .toSignalProducer()
            .flatMapError { _ in .empty }
            .map {
                ($0 as! RACTuple).second as! CLAuthorizationStatus
            }
    }
}
