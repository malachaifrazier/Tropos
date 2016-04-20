import UIKit

@objc(TRDailyForecastViewModel) public final class DailyForecastViewModel: NSObject {
    private let dailyForecast: DailyForecast
    private let temperatureFormatter: TemperatureFormatter

    public init(dailyForecast: DailyForecast, temperatureFormatter: TemperatureFormatter) {
        self.dailyForecast = dailyForecast
        self.temperatureFormatter = temperatureFormatter
    }

    public convenience init(dailyForecast: DailyForecast) {
        self.init(dailyForecast: dailyForecast, temperatureFormatter: TemperatureFormatter())
    }
}

public extension DailyForecastViewModel {
    var dayOfWeek: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ccc"
        return formatter.stringFromDate(dailyForecast.date)
    }

    var conditionsImageName: String {
        return dailyForecast.conditionsDescription
    }

    @available(watchOS, unavailable, message="load images using 'conditionsImageName' on watchOS")
    var conditionsImage: UIImage? {
        #if !os(watchOS)
            return UIImage(named: conditionsImageName, inBundle: .troposBundle, compatibleWithTraitCollection: nil)
        #else
            return nil
        #endif
    }

    var highTemperature: String {
        return temperatureFormatter.stringFromTemperature(dailyForecast.highTemperature)
    }

    var lowTemperature: String {
        return temperatureFormatter.stringFromTemperature(dailyForecast.lowTemperature)
    }
}
