import ReactiveCocoa
import Result

@objc(TRWeatherUpdater) public final class WeatherUpdater: NSObject {
    private let action: Action<AnyObject?, WeatherUpdate, NSError>

    @available(*, unavailable, message="use 'action' instead")
    public private(set) lazy var command: RACCommand = {
        return toRACCommand(self.action)
    }()

    @available(*, unavailable, message="observe 'action.executing' instead")
    public private(set) lazy var executing: RACSignal = {
        return self.action.executing.producer.map { $0._bridgeToObjectiveC() }.toRACSignal()
    }()

    public init(forecastAPIKey: String) {
        let forecastController = ForecastController(APIKey: forecastAPIKey)
        let geocodeController = GeocodeController()
        let locationController = LocationController()

        action = Action { _ in
            locationController.requestAlwaysAuthorization
                .promoteErrors(NSError.self)
                .then(locationController.requestLocation)
                .flatMap(.Merge, transform: geocodeController.reverseGeocode)
                .flatMap(.Merge, transform: forecastController.fetchWeatherUpdate)
        }
    }

    public var weatherUpdates: Signal<WeatherUpdate, NoError> {
        return action.values
    }

    public var errors: Signal<NSError, NoError> {
        return action.errors
    }

    public func update() -> Disposable {
        return action.apply(nil).start()
    }
}
