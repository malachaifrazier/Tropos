import ReactiveCocoa
import Result
import TroposCore
import WatchKit

class InterfaceController: WKInterfaceController {
    @IBOutlet private var conditionsImage: WKInterfaceImage!
    @IBOutlet private var messageLabel: WKInterfaceLabel!
    @IBOutlet private var updatedAtLabel: WKInterfaceLabel!

    var weatherUpdates: Signal<WeatherUpdate, NoError>!
    private var disposable: Disposable?

    override init() {
        super.init()
        updatedAtLabel.setHidden(true)
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        weatherUpdates = context as? Signal<WeatherUpdate, NoError> ?? WKExtension.sharedDelegate.allWeatherUpdates
        disposable = weatherUpdates.observeNext { [weak self] in self?.setWeatherUpdate($0) }

        if let cachedUpdate = WeatherUpdateCache().latestWeatherUpdate {
            setWeatherUpdate(cachedUpdate)
        }
    }

    override func didDeactivate() {
        super.didDeactivate()

        disposable?.dispose()
        disposable = nil
    }
}

private extension InterfaceController {
    func setWeatherUpdate(update: WeatherUpdate) {
        let viewModel = WeatherViewModel(weatherUpdate: update)
        conditionsImage.setImageNamed(viewModel.conditionsImageName)
        messageLabel.setAttributedText(viewModel.conditionsDescription)
        updatedAtLabel.setText(viewModel.updatedDateString)
        updatedAtLabel.setHidden(false)
    }
}
