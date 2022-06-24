import Foundation
import WebKit
import ExtoleConsumerAPI

class CampaignService: Campaign {
    public var PARTNER_SHARE_ID_PREFRENCES_KEY: String = "partner_share_id"
    public var ACCESS_TOKEN_PREFERENCES_KEY: String = "access_token"
    public var EXTOLE_SDK_TAG: String = "EXTOLE"

    let campaignId: Id<Campaign>
    let extole: ExtoleImpl
    let zone: Zone

    init(_ campaignId: Id<Campaign>, _ zone: Zone, _ extole: ExtoleImpl) {
        self.campaignId = campaignId
        self.zone = zone
        self.extole = extole
        self.extole.data["campaign_id"] = campaignId.value
    }

    func getProgram() -> String {
        extole.labels.joined(separator: ",")
    }

    func getId() -> Id<Campaign> {
        campaignId
    }

    func fetchZone(_ zoneName: String, completion: @escaping (Zone?, Campaign?, Error?) -> Void) {
        let localZoneContent = zone.get(zoneName) as? [String: Entry?]? ?? [:]
        if localZoneContent != nil {
            completion(Zone(zoneName: zoneName, campaignId: campaignId, content: localZoneContent), self, nil)
        } else {
            extole.fetchZone(zoneName, completion: completion)
        }
    }

    func getServices() -> ExtoleServices {
        extole.getServices()
    }

    func sendEvent(_ eventName: String, _ data: [String: Any?], completion: @escaping (Id<Event>?, Error?) -> Void) {
        extole.sendEvent(eventName, data, completion: completion)
    }

    func identify(_ email: String, _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void) {
        extole.identify(email, data, completion)
    }

    func getLogger() -> ExtoleLogger {
        extole.getLogger()
    }

    func getView() -> ExtoleView {
        extole.getView()
    }
}
