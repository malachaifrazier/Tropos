import WatchKit

extension WKExtension {
    static var sharedDelegate: ExtensionDelegate {
        return sharedExtension().delegate as! ExtensionDelegate
    }
}
