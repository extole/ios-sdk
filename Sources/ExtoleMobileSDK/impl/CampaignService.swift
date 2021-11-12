import Foundation
import UIKit
import ExtoleConsumerAPI

class CampaignService: Campaign {
    let programLabel: String
    let campaignId: Id<Campaign>
    let programDomain: String
    let customHeaders: [String: String]
    let labels: [String]
    let customData: [String: Any?]
    let zone: Zone

    init(_ programLabel: String, _ campaignId: Id<Campaign>, _ programDomain: String, _ zone: Zone,
         _ customHeaders: [String: String], _ labels: [String], _ customData: [String: Any?] = [:]) {
        self.programLabel = programLabel
        self.campaignId = campaignId
        self.programDomain = programDomain
        self.customHeaders = customHeaders
        self.labels = labels
        self.customData = customData
        self.zone = zone
    }

    func getProgram() -> String {
        programLabel
    }

    func getId() -> Id<Campaign> {
        campaignId
    }

    func getZone(_ zoneName: String, _ completion: @escaping (Zone?, Error?) -> Void) {
        let localZoneContent = zone.get(zoneName) as? [String: Entry?]? ?? [:]
        if localZoneContent != nil {
            completion(Zone(zoneName: zoneName, campaignId: campaignId, content: localZoneContent), nil)
        }
        doZoneRequest(zoneName: zoneName) { response, error in
            let campaignId = response?.header["x-extole-campaign"] ?? ""
            completion(Zone(zoneName: zoneName, campaignId: Id(campaignId), content: response?.body?.data), error)
        }
    }

    func emailShare(_ recipient: String, _ subject: String, _ message: String,
                    _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        data.forEach { key, value in
            customData[key] = value
        }
        customData["share.recipient"] = recipient
        customData["share.subject"] = subject
        customData["share.message"] = message
        customData["share.channel"] = "EXTOLE_EMAIL"
        customData["labels"] = labels.joined(separator: ",")
        customData["campaign_id"] = campaignId.value

        sendEvent("share", customData, completion)
    }

    func sendEvent(_ eventName: String, _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        data.forEach { key, value in
            customData[key] = value
        }
        let request = EventsEndpoints.postWithRequestBuilder(body:
        SubmitEventRequest(eventName: eventName, data: customData.mapValues { value in
            value as! String
        }))
        httpCallFor(request, programDomain, customHeaders)
            .execute { (response: ExtoleConsumerAPI.Response<ExtoleConsumerAPI.SubmitEventResponse>?, error: Error?) in
                completion(response?.body?._id != nil ? Id(response?.body?._id ?? "") : nil, error)
            }
    }

    func webViewBuilder(_ webView: UIWebView) -> ExtoleWebViewBuilder {
        return ExtoleWebViewBuilderImpl()
    }

    private func doZoneRequest(zoneName: String, completion: @escaping (Response<ZoneResponse>?, Error?) -> Void) {
        var modifiedData: [String: String] = [:]
        customData.forEach { key, value in
            modifiedData[key] = value as? String ?? ""
        }
        modifiedData["labels"] = labels.joined(separator: ",")
        modifiedData["campaign_id"] = campaignId.value
        let requestBuilder = ZonesEndpoints.renderWithRequestBuilder(body:
        RenderZoneRequest(eventName: zoneName, data: modifiedData))

        httpCallFor(requestBuilder, programDomain + "/api", customHeaders)
            .execute { (response: ExtoleConsumerAPI.Response<ExtoleConsumerAPI.ZoneResponse>?, error: Error?) in
                completion(response, error)
            }
    }

}
