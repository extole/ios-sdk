import Foundation

public class Zones {
    private var _zonesResponse: [ZoneKey: Zone?] = [:]
    private let accessQueue = DispatchQueue(label: "com.extole.zones.access", attributes: .concurrent)
    
    public var zonesResponse: [ZoneKey: Zone?] {
        get {
            return accessQueue.sync { _zonesResponse }
        }
    }
    
    public func getZone(for key: ZoneKey) -> Zone? {
        return accessQueue.sync { _zonesResponse[key] ?? nil }
    }
    
    public func setZone(_ zone: Zone?, for key: ZoneKey) {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?._zonesResponse[key] = zone
        }
    }
    
    public func getAllKeys() -> [ZoneKey] {
        return accessQueue.sync { Array(_zonesResponse.keys) }
    }
    
    public func getAllValues() -> [Zone?] {
        return accessQueue.sync { Array(_zonesResponse.values) }
    }
}

public class ZoneKey: Hashable, Equatable, Comparable, CustomStringConvertible {
    var zoneName: String;
    var data: [String: Any?];
    
    public init(_ zoneName: String, _ data: [String: Any?]) {
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
    
    public static func < (lhs: ZoneKey, rhs: ZoneKey) -> Bool {
        return "\(lhs.zoneName)" < "\(rhs.zoneName)"
   }
    
    public var description: String {
        let dataString = data.isEmpty ? "" : data.map { "\($0.key):\($0.value ?? "nil")" }.joined(separator: ",")
        return "\(zoneName):[\(dataString)]"
    }
}
