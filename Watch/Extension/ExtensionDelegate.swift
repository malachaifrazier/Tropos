import ReactiveCocoa
import Result
import TroposCore
import WatchConnectivity
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    private var applicationContexts: Signal<[String: AnyObject], NoError>!
    private var weatherUpdater: WeatherUpdater!

    var allWeatherUpdates: Signal<WeatherUpdate, NoError> {
        return Signal.merge([weatherUpdater.weatherUpdates, iphoneWeatherUpdates])
    }

    private var iphoneWeatherUpdates: Signal<WeatherUpdate, NoError> {
        return applicationContexts
            .map {
                WatchUpdateController.defaultController?.unpackWeatherUpdate(fromContext: $0)
            }
            .ignoreNil()
    }

    func applicationDidFinishLaunching() {
        WatchUpdateController.defaultController?.activateSession(delegate: self)

        rac_signalForSelector(#selector(WCSessionDelegate.session(_:didReceiveApplicationContext:)))
            .toSignalProducer()
            .flatMapError { _ in .empty }
            .map { ($0 as! RACTuple).second as! [String: AnyObject] }
            .startWithSignal { signal, _ in
                applicationContexts = signal
            }

        weatherUpdater = WeatherUpdater(forecastAPIKey: TRForecastAPIKey)
        weatherUpdater.errors.observeNext { print("WEATHER UPDATE FAILED:", $0) }
        weatherUpdater.onWeatherUpdated = {
            WeatherUpdateCache().archiveWeatherUpdate($0)
        }
    }

    func applicationDidBecomeActive() {
        weatherUpdater.update()
    }
}

private extension ExtensionDelegate {
    func cacheWeatherUpdate(update: WeatherUpdate) {
        WeatherUpdateCache().archiveWeatherUpdate(update)
    }
}
