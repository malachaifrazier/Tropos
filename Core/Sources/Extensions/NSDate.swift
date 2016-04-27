import Foundation

extension NSDate {
    @objc(tr_precedes:) func precedes(date: NSDate) -> Bool {
        return compare(date) == .OrderedAscending
    }
}
