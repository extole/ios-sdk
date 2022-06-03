import Foundation
import WebKit
import ExtoleConsumerAPI

class CampaignService: Campaign {
    let campaignId: Id<Campaign>
    let extole: ExtoleImpl
    let zone: Zone

    init(_ campaignId: Id<Campaign>, _ zone: Zone, _ extole: ExtoleImpl) {
        self.campaignId = campaignId
        self.zone = zone
        self.extole = extole
    }

    func getProgram() -> String {
        extole.labels.joined(separator: ",")
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
            completion(Zone(zoneName: zoneName, campaignId: Id(campaignId),
                content: response?.body?.data as? [String: Entry?]), error)
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
        customData["labels"] = extole.labels.joined(separator: ",")
        customData["campaign_id"] = campaignId.value

        sendEvent("share", customData, completion)
    }

    func sendEvent(_ eventName: String, _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        data.forEach { key, value in
            customData[key] = value
        }
        let request = EventEndpoints.postWithRequestBuilder(body:
        SubmitEventRequest(eventName: eventName, data: customData.mapValues { value in
            value as! String
        }))
        httpCallFor(request, extole.programDomain, extole.customHeaders)
            .execute { (response: Response<SubmitEventResponse>?, error: Error?) in
                completion(response?.body?._id != nil ? Id(response?.body?._id ?? "") : nil, error)
            }
    }

    func webView(headers: [String: String], data: [String: String]) -> ExtoleWebView {
        NSLog("CampaignService headers \(extole.customHeaders)")
        var headersParams = headers
        extole.customHeaders.forEach { key, value in
            headersParams[key] = value
        }
        var dataParams = data
        extole.data.forEach { key, value in
            dataParams[key] = value
        }
        return ExtoleWebViewService(extole.programDomain, dataParams, headersParams)
    }

    private func doZoneRequest(zoneName: String, completion: @escaping (Response<ZoneResponse>?, Error?) -> Void) {
        var modifiedData: [String: String] = [:]
        extole.data.forEach { key, value in
            modifiedData[key] = value as? String ?? ""
        }
        modifiedData["labels"] = extole.labels.joined(separator: ",")
        modifiedData["campaign_id"] = campaignId.value
        let requestBuilder = ZoneEndpoints.renderWithRequestBuilder(body:
        RenderZoneRequest(eventName: zoneName, data: modifiedData))

        httpCallFor(requestBuilder, extole.programDomain + "/api", extole.customHeaders)
            .execute { (response: Response<ZoneResponse>?, error: Error?) in
                completion(response, error)
            }
    }

}
