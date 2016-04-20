import TroposCore
import WatchKit

class InterfaceController: WKInterfaceController {
    @IBOutlet private var conditionsImage: WKInterfaceImage!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        let clearForecast = DailyForecast(
            date: NSDate(),
            conditionsDescription: "clear-day",
            highTemperature: Temperature(celsiusValue: 25),
            lowTemperature: Temperature(celsiusValue: 10)
        )
        let viewModel = DailyForecastViewModel(dailyForecast: clearForecast)
        conditionsImage.setImageNamed(viewModel.conditionsImageName)
    }
}
