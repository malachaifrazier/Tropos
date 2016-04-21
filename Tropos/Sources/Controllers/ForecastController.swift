import CoreLocation
import Foundation
import ReactiveCocoa
import TroposCore

private var baseURLComponents: NSURLComponents {
    let components = NSURLComponents()
    components.scheme = "https"
    components.host = "api.forecast.io"
    components.path = "/forecast/\(TRForecastAPIKey)"
    return components
}

private let forecastAPIExclusions = "minutely,hourly,alerts,flags"

@objc(TRForecastController) final class ForecastController: NSObject {
    private let session: NSURLSession

    init(session: NSURLSession) {
        self.session = session
    }

    override convenience init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["Accept": "application/json"]
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        self.init(session: NSURLSession(configuration: configuration))
    }

    func fetchWeatherUpdate(forPlacemark placemark: CLPlacemark) -> RACSignal {
        let coordinate = placemark.location!.coordinate

        let conditionsURL = URLForCurrentConditions(atLatitude: coordinate.latitude, longitude: coordinate.longitude, yesterday: false)
        let yesterdaysConditionsURL = URLForCurrentConditions(atLatitude: coordinate.latitude, longitude: coordinate.longitude, yesterday: true)

        return RACSignal
            .combineLatest([
                fetchConditions(fromURL: conditionsURL),
                fetchConditions(fromURL: yesterdaysConditionsURL),
            ])
            .map {
                let results = $0 as! RACTuple
                return WeatherUpdate(
                    placemark: placemark,
                    currentConditionsJSON: results.first as! [String: AnyObject],
                    yesterdaysConditionsJSON: results.second as! [String: AnyObject]
                )
            }
            .deliverOnMainThread()
    }
}

private extension ForecastController {
    func fetchConditions(fromURL URL: NSURL) -> RACSignal {
        return session.fetchData(fromURL: URL).flattenMap { data in
            parseJSON(fromData: data as! NSData)
        }
    }
}

private func parseJSON(fromData data: NSData) -> RACSignal {
    return RACSignal.createSignal { subscriber in
        do {
            let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            subscriber.sendNext(JSON)
            subscriber.sendCompleted()
        } catch let error as NSError {
            subscriber.sendError(error)
        }

        return nil
    }
}

private extension NSURLSession {
    func fetchData(fromURL URL: NSURL) -> RACSignal {
        return RACSignal.createSignal { subscriber in
            let task = self.dataTaskWithURL(URL) { data, response, error in
                if error != nil {
                    subscriber.sendError(error)
                    return
                }

                if !responseContainsSuccessfulStatusCode(response as! NSHTTPURLResponse) {
                    let error = NSError(domain: TRErrorDomain, code: 200, userInfo: nil)
                    subscriber.sendError(error)
                    return
                }

                subscriber.sendNext(data)
                subscriber.sendCompleted()
            }

            task.resume()

            return RACDisposable(block: task.cancel)
        }
    }
}

private func URLForCurrentConditions(atLatitude latitude: Double, longitude: Double, yesterday: Bool) -> NSURL {
    let components = baseURLComponents

    let date = yesterday ? NSCalendar.currentCalendar().yesterday : nil
    let locationPathComponent = pathComponent(forLatitude: latitude, longitude: longitude, date: date)
    components.path = components.path!.stringByAppendingString(locationPathComponent)

    let exclusions = NSURLQueryItem(name: "exclude", value: forecastAPIExclusions)
    components.queryItems = [exclusions]

    return components.URL!
}

private func responseContainsSuccessfulStatusCode(response: NSHTTPURLResponse) -> Bool {
    return (200..<300).contains(response.statusCode)
}

private func pathComponent(forLatitude latitude: Double, longitude: Double, date: NSDate?) -> String {
    var path = String(format: "/%f,%f", latitude, longitude)

    if let date = date {
        let dateString = String(format: ",%.0f", date.timeIntervalSince1970)
        path.appendContentsOf(dateString)
    }

    return path
}

private extension NSCalendar {
    var yesterday: NSDate? {
        return dateByAddingUnit(.Day, value: 1, toDate: NSDate(), options: .SearchBackwards)
    }
}
