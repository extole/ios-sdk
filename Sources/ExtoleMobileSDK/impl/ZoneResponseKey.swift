import Foundation

public class ZoneResponseKey: Hashable, Comparable {

    public let zoneName: String

    init(_ zoneName: String) {
        self.zoneName = zoneName
    }

    public static func == (leftHandSide: ZoneResponseKey, rightHandSite: ZoneResponseKey) -> Bool {
        leftHandSide.zoneName == rightHandSite.zoneName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(zoneName)
    }

    public static func < (lhs: ZoneResponseKey, rhs: ZoneResponseKey) -> Bool {
        return lhs.zoneName > rhs.zoneName
    }
}
