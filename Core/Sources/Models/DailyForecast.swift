import Foundation

public struct DailyForecast {
    public var date: NSDate
    public var conditionsDescription: String
    public var highTemperature: Temperature
    public var lowTemperature: Temperature

    public init(date: NSDate, conditionsDescription: String, highTemperature: Temperature, lowTemperature: Temperature) {
        self.date = date
        self.conditionsDescription = conditionsDescription
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
    }

    public init?(JSON: AnyObject?) {
        guard let dict = JSON as? [String: AnyObject],
            let time = dict["time"] as? Double,
            let icon = dict["icon"] as? String,
            let temperatureMax = dict["temperatureMax"] as? Int,
            let temperatureMin = dict["temperatureMin"] as? Int
            else {
                return nil
            }

        self.init(
            date: NSDate(timeIntervalSince1970: time),
            conditionsDescription: icon,
            highTemperature: Temperature(fahrenheitValue: temperatureMax),
            lowTemperature: Temperature(fahrenheitValue: temperatureMin)
        )
    }
}
