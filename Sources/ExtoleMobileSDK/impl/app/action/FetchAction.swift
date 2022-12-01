import Foundation
import ObjectMapper
import AdSupport
import UIKit

public class FetchAction: Action, CustomStringConvertible {
    public static var type: ActionType = ActionType.FETCH

    var zones: [String]?
    var data: [String: String]?
    var actionType: String = type.rawValue
    private var zoneFetcher: ZoneFetcher?

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        extole.getLogger().debug("FetchAction, event=\(event)")

        var allData = prepareRequestData(extole: extole)
        zoneFetcher = ZoneFetcher(programDomain: extole.programDomain, logger: extole.getLogger(), extole: extole)
        zoneFetcher?.getZones(zonesName: zones ?? [], data: allData,
            programLabels: extole.labels, customHeaders: extole.getHeaders()) { [self] response in
            response.forEach({ (key: ZoneResponseKey, value: Zone?) in
                extole.zones.zonesResponse[key.zoneName] = value
            })
        }
    }

    private func prepareRequestData(extole: ExtoleImpl) -> [String: String] {
        let identifierManager = ASIdentifierManager.shared()
        var systemVersion = UIDevice.current.systemVersion
        var deviceId = ""
        if identifierManager.isAdvertisingTrackingEnabled {
            deviceId = identifierManager.advertisingIdentifier.uuidString
        }

        var allData: [String: String] = [:]
        allData["device_id"] = deviceId
        allData["os"] = systemVersion
        extole.data.forEach { (key: String, value: String) in
            allData[key] = value
        }
        data?.forEach({ (key: String, value: String) in
            allData[key] = value
        })
        return allData
    }

    override init() {
        super.init()
    }

    init(zones: [String], data: [String: String] = [:]) {
        super.init()
        self.zones = zones
        self.data = data
    }

    public func getZones() -> [String]? {
        zones
    }

    public func getData() -> [String: String]? {
        data
    }

    public override func getType() -> ActionType {
        ActionType.FETCH
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        zones <- map["zones"]
        data <- map["data"]
        actionType <- map["type"]
    }

    public var description: String { return "FetchAction[zones:\(zones), data:\(data)]" }
}
