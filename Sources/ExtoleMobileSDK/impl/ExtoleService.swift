import Foundation
import ExtoleConsumerAPI
import WebKit

public class ExtoleService: Extole {
    public var PARTNER_SHARE_ID_PREFRENCES_KEY: String = "partner_share_id"
    public var ACCESS_TOKEN_PREFERENCES_KEY: String = "access_token"
    public var EXTOLE_SDK_TAG: String = "EXTOLE"
    private let PREFETCH_ZONE: String = "prefetch"
    private let ACCESS_TOKEN_HEADER_NAME = "x-extole-token"
    private let CAMPAIGN_ID_HEADER_NAME = "x-extole-campaign"

    var programDomain: String
    var appName: String
    var appData: [String: String]
    var data: [String: String]
    var labels: [String]
    var customHeaders: [String: String] = [:]

    private var sandbox: String
    private var debugEnabled: Bool
    private var personIdentifier: String?

    private let zoneService: ZoneService
    private let persistance: UserDefaults = UserDefaults.standard
    private var zonesResponse: [ZoneResponseKey: Zone?] = [:]

    public init(programDomain: String, applicationName: String, personIdentifier: String? = nil,
                applicationData: [String: String] = [:], data: [String: String] = [:], labels: [String] = [],
                sandbox: String = "prod-prod", debugEnabled: Bool = false) {
        self.programDomain = programDomain
        self.appName = applicationName
        self.appData = applicationData
        self.data = data
        self.labels = labels
        self.sandbox = sandbox
        self.debugEnabled = debugEnabled
        self.zoneService = ZoneService(programDomain: programDomain)
        self.personIdentifier = personIdentifier
        initAccessToken { [unowned self] in
            identify(personIdentifier) { (_, _) in
                prefetch()
            }
        }
    }

    private func prefetch() {
        let dispatchGroup = DispatchGroup()
        var responses: [ZoneResponseKey: Zone?] = [:]
        zoneService.getZones(zonesName: [PREFETCH_ZONE], data: data,
            programLabels: labels, customHeaders: customHeaders) { [self] response in
            let zones = [String](response.values.map { value -> [String] in
                value?.content?["zones"]??.jsonValue as? [String] ?? [String]()
            }.joined())
            if !zones.isEmpty {
                dispatchGroup.enter()
                zoneService.getZones(zonesName: zones, data: data, programLabels: labels,
                    customHeaders: customHeaders) { response in
                    responses = response
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                zonesResponse = responses
            }
        }
        dispatchGroup.wait()
    }

    public func getZone(_ zoneName: String, completion: @escaping (Zone?, Campaign?, Error?) -> Void) {
        doZoneRequest(zoneName: zoneName) { [unowned self] response, error in
            let campaignId = response?.header[CAMPAIGN_ID_HEADER_NAME] ?? ""
            let zone = Zone(zoneName: zoneName, campaignId: Id(campaignId), content: response?.body?.data)
            let campaign = CampaignService(Id(campaignId), zone, self)
            completion(zone, campaign, error)
        }
    }

    public func sendEvent(_ eventName: String, _ data: [String: Any?],
                          completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        self.data.forEach { key, value in
            customData[key] = value
        }
        let request = EventEndpoints.postWithRequestBuilder(
            body: SubmitEventRequest(eventName: eventName, data: customData.mapValues { value in
                value as! String
            }))
        httpCallFor(request, self.programDomain, self.customHeaders)
            .execute { [self] (response, error) in
                if response?.header[ACCESS_TOKEN_HEADER_NAME] != nil {
                    setAccessToken(accessToken: response?.header[ACCESS_TOKEN_HEADER_NAME] ?? "")
                }
                completion(response?.body?._id != nil ? Id(response?.body?._id ?? "") : nil, error)
            }
    }

    public func copy(programDomain: String? = nil, applicationName: String? = nil, email: String? = nil,
                     applicationData: [String: String]? = nil, data: [String: String]? = nil,
                     labels: [String]? = nil, sandbox: String? = nil, debugEnabled: Bool? = nil) -> Extole {
        return ExtoleService(programDomain: programDomain ?? self.programDomain, applicationName: applicationName ?? self.appName,
            personIdentifier: email ?? self.personIdentifier, data: data ?? self.data,
            labels: labels ?? self.labels, sandbox: sandbox ?? self.sandbox,
            debugEnabled: debugEnabled ?? self.debugEnabled)
    }

    public func webView(headers: [String: String] = [:], data: [String: String] = [:]) -> ExtoleWebView {
        var headersParams = headers
        customHeaders.forEach { key, value in
            headersParams[key] = value
        }
        var dataParams = data
        self.data.forEach { key, value in
            dataParams[key] = value
        }
        return ExtoleWebViewService(programDomain, dataParams, headersParams)
    }

    private func identify(_ identifier: String?, _ data: [String: Any?] = [:],
                          _ completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        self.data.forEach { key, value in
            customData[key] = value
        }
        if identifier != nil {
            customData["email"] = identifier
        }
        sendEvent("identify", customData, completion: completion)
    }

    private func initAccessToken(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        let accessToken = persistance.string(forKey: ACCESS_TOKEN_PREFERENCES_KEY) ?? ""
        dispatchGroup.enter()
        if accessToken.isEmpty {
            createAccessToken(completion: completion, dispatchGroup)
        } else {
            customHeaders["Authorization"] = "Bearer " + accessToken
            let request = AuthorizationEndpoints.getTokenDetailsWithRequestBuilder()
            httpCallFor(request, self.programDomain + "/api", self.customHeaders)
                .execute { [self] (_: Response<TokenResponse>?, error: Error?) in
                    if error != nil {
                        switch error as! ErrorResponse? {
                        case .error(403, _, _):
                            createAccessToken(completion: completion, dispatchGroup)
                        default:
                            dispatchGroup.leave()
                        }
                    } else {
                        setAccessToken(accessToken: accessToken, dispatchGroup)
                        completion()
                    }
                }
        }
        _ = dispatchGroup.wait(timeout: .now() + 3.0)
    }

    private func createAccessToken(completion: @escaping () -> Void, _ dispatchGroup: DispatchGroup) {
        let request = AuthorizationEndpoints.createTokenWithRequestBuilder()
        httpCallFor(request, self.programDomain + "/api", self.customHeaders)
            .execute { [self] (tokenResponse: Response<TokenResponse>?, _: Error?) in
                let accessToken = tokenResponse?.body?.accessToken ?? ""
                setAccessToken(accessToken: accessToken, dispatchGroup)
                completion()
            }
    }

    private func setAccessToken(accessToken: String, _ dispatchGroup: DispatchGroup? = nil) {
        customHeaders["Authorization"] = "Bearer " + accessToken
        persistance.setValue(accessToken, forKey: ACCESS_TOKEN_PREFERENCES_KEY)
        dispatchGroup?.leave()
    }

    private func doZoneRequest(zoneName: String, completion: @escaping (Response<ZoneResponse>?, Error?) -> Void) {
        var modifiedData = data
        modifiedData["labels"] = labels.joined(separator: ",")
        let requestBuilder = ZoneEndpoints.renderWithRequestBuilder(
            body: RenderZoneRequest(eventName: zoneName, data: modifiedData))

        httpCallFor(requestBuilder, self.programDomain + "/api", self.customHeaders)
            .execute { (response: Response<ZoneResponse>?, error: Error?) in
                completion(response, error)
            }
    }

}
