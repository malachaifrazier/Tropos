import UIKit

extension UIFont {
    @available(watchOS, unavailable, message="custom fonts not available on watchOS")
    static func defaultUltraLightFont(size size: CGFloat) -> UIFont {
#if !os(watchOS)
        return UIFont(name: "DINNextLTPro-Light", size: size)!
#else
        fatalError("unimplemented")
#endif
    }
}
