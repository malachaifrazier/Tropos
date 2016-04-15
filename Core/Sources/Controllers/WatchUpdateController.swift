import WatchConnectivity

private let WeatherUpdateDataKey = "weatherUpdateData"

@objc(TRWatchUpdateController) public final class WatchUpdateController: NSObject {
    public static let defaultController: WatchUpdateController? = {
        guard WCSession.isSupported() else {
            log("watch session not supported")
            return nil
        }
        return WatchUpdateController(session: WCSession.defaultSession())
    }()

    private let session: WCSession

    private init(session: WCSession) {
        self.session = session
        super.init()
    }

    public func activateSession(delegate delegate: WCSessionDelegate) {
        self.session.delegate = delegate
        self.session.activateSession()
    }

    private func ifPaired(@noescape body: () throws -> Void) rethrows {
#if os(iOS)
        guard session.paired else {
            log("watch not paired")
            return
        }
#endif
        try body()
    }
}

public extension WatchUpdateController {
    func sendWeatherUpdate(update: WeatherUpdate?) {
        guard let update = update else { return }
        ifPaired {
            do {
                let context = packWeatherUpdate(update)
                try session.updateApplicationContext(context)
                log("sent latest weather update")
            } catch {
                log("failed to update application context: \(error)")
            }
        }
    }

    func packWeatherUpdate(update: WeatherUpdate) -> [String: AnyObject] {
        let data = NSKeyedArchiver.archivedDataWithRootObject(update)
        return [WeatherUpdateDataKey: data]
    }

    func unpackWeatherUpdate(fromContext context: [String: AnyObject]) -> WeatherUpdate? {
        guard let data = context[WeatherUpdateDataKey] as? NSData else { return nil }
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? WeatherUpdate
    }
}

private func log(message: String) {
    NSLog("\(WatchUpdateController.self): \(message)")
}
