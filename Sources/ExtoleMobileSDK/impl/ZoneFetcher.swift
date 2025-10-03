import Foundation
import ExtoleConsumerAPI

public class ZoneFetcher {
    private let HEADER_CAMPAIGN_ID = "x-extole-campaign"
    private let programDomain: String
    private let logger: ExtoleLogger?
    private let extole: Extole

    init(programDomain: String, logger: ExtoleLogger?, extole: Extole) {
        self.programDomain = programDomain
        self.logger = logger
        self.extole = extole
    }

    public func getZones(zonesName: [String], data: [String: Any?],
                         programLabels: [String],
                         customHeaders: [String: String],
                         completion: @escaping ([ZoneResponseKey: Zone?]) -> Void) {
        let labels = programLabels.joined(separator: ",")
        var prefetchedResponses: [ZoneResponseKey: Zone?] = [:]
        var requestData: [String: String] = [:]
        data.forEach { key, value in
            requestData[key] = value as? String
        }
        requestData["labels"] = labels
        let dispatchGroup = DispatchGroup()

        zonesName.forEach { (zoneName) in
            dispatchGroup.enter()
            let requestBuilder = ZoneEndpoints.renderWithRequestBuilder(
              body: RenderZoneRequest(eventName: zoneName, jwt: nil, idToken: nil, data: requestData))
            httpCallFor(requestBuilder, programDomain + "/api", customHeaders)
              .execute { [self] (response: Response<ZoneResponse>?, error: Error?) in
                  if error != nil {
                      logger?.error("""
                                    Zone fetch error \(error.debugDescription),
                                    labels=\(labels), zoneName=\(zoneName)
                                    """)
                  }
                  if response != nil && response?.body != nil {
                      let campaignId = response?.body?.campaignId ?? ""
                      prefetchedResponses[ZoneResponseKey(zoneName, labels: labels)] = Zone(zoneName: zoneName,
                        campaignId: Id(campaignId), content: response?.body?.data, extole: extole)
                  }
                  dispatchGroup.leave()
              }
        }
        dispatchGroup.notify(queue: .main) {
            completion(prefetchedResponses)
        }
    }
}
