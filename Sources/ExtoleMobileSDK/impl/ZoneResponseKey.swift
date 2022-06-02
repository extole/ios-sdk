import Foundation

class ZoneResponseKey: Hashable {

    let zoneName: String

    init(_ zoneName: String) {
        self.zoneName = zoneName
    }

    static func == (leftHandSide: ZoneResponseKey, rightHandSite: ZoneResponseKey) -> Bool {
        leftHandSide.zoneName == rightHandSite.zoneName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(zoneName)
    }
}
