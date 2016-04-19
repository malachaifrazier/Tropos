import TroposCore
import WatchKit

class InterfaceController: WKInterfaceController {
    @IBOutlet private var messageLabel: WKInterfaceLabel!
    @IBOutlet private var updatedAtLabel: WKInterfaceLabel!

    override init() {
        super.init()
        updatedAtLabel.setHidden(true)
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        if let update = context as? WeatherUpdate ?? WeatherUpdateCache().latestWeatherUpdate {
            setWeatherUpdate(update)
        }
    }

    func setWeatherUpdate(update: WeatherUpdate) {
        let viewModel = WeatherViewModel(weatherUpdate: update)
        messageLabel.setAttributedText(viewModel.conditionsDescription)
        updatedAtLabel.setText(viewModel.updatedDateString)
        updatedAtLabel.setHidden(false)
    }
}
