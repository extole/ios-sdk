import Foundation

public class ZoneResponseKey: Hashable, Comparable {

    public let zoneName: String
    public let labels: String

    init(_ zoneName: String, labels: String = "") {
        self.zoneName = zoneName
        self.labels = labels
    }

    public static func == (leftHandSide: ZoneResponseKey, rightHandSite: ZoneResponseKey) -> Bool {
        leftHandSide.zoneName == rightHandSite.zoneName && leftHandSide.labels == rightHandSite.labels
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(zoneName)
        hasher.combine(labels)
    }

    public static func < (lhs: ZoneResponseKey, rhs: ZoneResponseKey) -> Bool {
        return lhs.zoneName > rhs.zoneName
    }
}
