import TroposCore
import WatchConnectivity
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    func applicationDidFinishLaunching() {
        WatchUpdateController.defaultController?.activateSession(delegate: self)
    }

    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String: AnyObject]) {
        guard let update = WatchUpdateController.defaultController?.unpackWeatherUpdate(fromContext: applicationContext) else { return }
        WeatherUpdateCache().archiveWeatherUpdate(update)
        let interface = WKExtension.sharedExtension().rootInterfaceController as! InterfaceController
        interface.setWeatherUpdate(update)
    }
}
