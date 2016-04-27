import CoreLocation
import Foundation
import ReactiveCocoa
import Result

private let forecastAPIExclusions = "minutely,hourly,alerts,flags"

final class ForecastController {
    private let APIKey: String
    private let session: NSURLSession

    init(APIKey: String, session: NSURLSession) {
        self.APIKey = APIKey
        self.session = session
    }

    convenience init(APIKey: String) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["Accept": "application/json"]
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        self.init(APIKey: APIKey, session: NSURLSession(configuration: configuration))
    }

    func fetchWeatherUpdate(forPlacemark placemark: CLPlacemark) -> SignalProducer<WeatherUpdate, NSError> {
        let coordinate = placemark.location!.coordinate

        let conditions = fetchConditions(fromURL: URLForCurrentConditions(atLatitude: coordinate.latitude, longitude: coordinate.longitude, yesterday: false))
        let yesterdaysConditions = fetchConditions(fromURL: URLForCurrentConditions(atLatitude: coordinate.latitude, longitude: coordinate.longitude, yesterday: true))

        return conditions.combineLatestWith(yesterdaysConditions)
            .flatMap(.Merge) { today, yesterday -> SignalProducer<WeatherUpdate, NSError> in
                if let update = WeatherUpdate(placemark: placemark, currentConditionsJSON: today, yesterdaysConditionsJSON: yesterday) {
                    return SignalProducer(value: update)
                } else {
                    let error = NSError(domain: TRErrorDomain, code: 201, userInfo: nil)
                    return SignalProducer(error: error)
                }
            }
    }
}

private extension ForecastController {
    func fetchConditions(fromURL URL: NSURL) -> SignalProducer<[String: AnyObject], NSError> {
        return session.fetchData(fromURL: URL)
            .flatMap(.Merge, transform: parseJSON)
            .map { $0 as! [String: AnyObject] }
    }

    func URLForCurrentConditions(atLatitude latitude: Double, longitude: Double, yesterday: Bool) -> NSURL {
        let components = baseURLComponents

        let date = yesterday ? NSCalendar.currentCalendar().yesterday : nil
        let locationPathComponent = pathComponent(forLatitude: latitude, longitude: longitude, date: date)
        components.path = components.path!.stringByAppendingString(locationPathComponent)

        let exclusions = NSURLQueryItem(name: "exclude", value: forecastAPIExclusions)
        components.queryItems = [exclusions]

        return components.URL!
    }

    var baseURLComponents: NSURLComponents {
        let components = NSURLComponents()
        components.scheme = "https"
        components.host = "api.forecast.io"
        components.path = "/forecast/\(APIKey)"
        return components
    }
}

private func parseJSON(fromData data: NSData) -> SignalProducer<AnyObject, NSError> {
    func parse() -> Result<AnyObject, NSError> {
        return Result(try NSJSONSerialization.JSONObjectWithData(data, options: []))
    }

    return .attempt(parse)
}

private extension NSURLSession {
    func fetchData(fromURL URL: NSURL) -> SignalProducer<NSData, NSError> {
        return rac_dataWithRequest(NSURLRequest(URL: URL))
            .flatMap(.Merge) { data, response -> SignalProducer<NSData, NSError> in
                if responseContainsSuccessfulStatusCode(response as! NSHTTPURLResponse) {
                    return SignalProducer(value: data)
                } else {
                    let error = NSError(domain: TRErrorDomain, code: 200, userInfo: nil)
                    return SignalProducer(error: error)
                }
            }
    }
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
