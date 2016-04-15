import TroposCore
import WatchKit

private let dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    return formatter
}()

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
        messageLabel.setText(update.conditionsDescription)
        let date = dateFormatter.stringFromDate(update.date)
        updatedAtLabel.setText("Updated: \(date)")
        updatedAtLabel.setHidden(false)
    }
}
