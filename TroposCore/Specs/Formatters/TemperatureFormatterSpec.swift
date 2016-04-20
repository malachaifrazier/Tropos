import TroposCore
import Quick
import Nimble

final class TemperatureFormatterSpec: QuickSpec {
    override func spec() {
        it("can format fahrenheit temperatures in celsius") {
            let formatter = TemperatureFormatter(unitSystem: .Metric)
            let temperature = Temperature(fahrenheitValue: 32)
            expect(formatter.stringFromTemperature(temperature)) == "0°"
        }

        it("can format celsius temperatures in fahrenheit") {
            let formatter = TemperatureFormatter(unitSystem: .Imperial)
            let temperature = Temperature(celsiusValue: 0)
            expect(formatter.stringFromTemperature(temperature)) == "32°"
        }

        it("uses the default unit system in settings if not specified") {
            SettingsController().unitSystem = .Metric
            let formatter = TemperatureFormatter()
            let temperature = Temperature(fahrenheitValue: 32)
            expect(formatter.stringFromTemperature(temperature)) == "0°"
        }
    }
}
