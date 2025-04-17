import Foundation

public class Zones {
    public var zonesResponse: [ZoneKey: Zone?] = [:]
}

public class ZoneKey: Hashable, Equatable {
    var zoneName: String;
    var data: [String: Any?];
    
    init(_ zoneName: String, _ data: [String: Any?]) {
        self.zoneName = zoneName
        self.data = data
    }
    
    public static func == (lhs: ZoneKey, rhs: ZoneKey) -> Bool {
        guard lhs.zoneName == rhs.zoneName else { return false }
        
        // Compare dictionaries manually (simple shallow equality)
        guard lhs.data.keys == rhs.data.keys else { return false }
        for key in lhs.data.keys {
            let lhsValue = lhs.data[key] as? NSObject
            let rhsValue = rhs.data[key] as? NSObject
            if lhsValue != rhsValue {
                return false
            }
        }
        return true
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(zoneName)
        for key in data.keys.sorted() {
            hasher.combine(key)
            if let value = data[key] as? NSObject {
                hasher.combine(value.hash)
            }
        }
    }
}
