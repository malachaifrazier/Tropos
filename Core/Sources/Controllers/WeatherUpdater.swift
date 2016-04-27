import ReactiveCocoa
import Result

private let WeatherUpdateTaskName = "com.thoughtbot.carlweathers.updateWeather"

@objc(TRWeatherUpdater) public final class WeatherUpdater: NSObject {
    private var action: Action<AnyObject?, WeatherUpdate, NSError>!

    public var onWeatherUpdated: (WeatherUpdate -> Void)?

    @available(*, unavailable, message="use 'action' instead")
    public private(set) lazy var command: RACCommand = {
        return toRACCommand(self.action)
    }()

    @available(*, unavailable, message="observe 'action.executing' instead")
    public private(set) lazy var executing: RACSignal = {
        return self.action.executing.producer.map { $0._bridgeToObjectiveC() }.toRACSignal()
    }()

    public init(forecastAPIKey: String) {
        super.init()

        let forecastController = ForecastController(APIKey: forecastAPIKey)
        let geocodeController = GeocodeController()
        let locationController = LocationController()

        action = Action { [weak self] _ in
            let update = locationController.requestAlwaysAuthorization
                .promoteErrors(NSError.self)
                .then(locationController.requestLocation)
                .flatMap(.Merge, transform: geocodeController.reverseGeocode)
                .flatMap(.Merge, transform: forecastController.fetchWeatherUpdate)
                .on(next: { self?.onWeatherUpdated?($0) })

            let task: SignalProducer<WeatherUpdate, NSError>
#if os(iOS)
            task = UIApplication.sharedApplication().rac_backgroundTask(name: WeatherUpdateTaskName, producer: update)
#else
            task = NSProcessInfo.processInfo().rac_expiringActivity(reason: WeatherUpdateTaskName, producer: update)
#endif
            return task.observeOn(UIScheduler())
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
