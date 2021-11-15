import Foundation
import ExtoleConsumerAPI
import UIKit

public class ExtoleService: Extole {
    public var PARTNER_SHARE_ID_PREFRENCES_KEY: String = "partner_share_id"
    public var ACCESS_TOKEN_PREFERENCES_KEY: String = "access_token"
    public var EXTOLE_SDK_TAG: String = "EXTOLE"
    private let PREFETCH_ZONE: String = "prefetch"

    private var programDomain: String
    private var appName: String
    private var appData: [String: String]
    private var data: [String: String]
    private var labels: [String]
    private var sandbox: String
    private var debugEnabled: Bool

    private let zoneService: ZoneService
    private var customHeaders: [String: String] = [:]
    private var persistance: UserDefaults = UserDefaults.standard
    private var zonesResponse: [ZoneResponseKey: Zone?] = [:]
    private var me: Me = Me()

    public init(programDomain: String, applicationName: String, applicationData: [String: String] = [:],
                data: [String: String] = [:], labels: [String] = [], sandbox: String = "prod-prod",
                debugEnabled: Bool = false) {
        self.programDomain = programDomain
        self.appName = applicationName
        self.appData = applicationData
        self.data = data
        self.labels = labels
        self.sandbox = sandbox
        self.debugEnabled = debugEnabled
        self.zoneService = ZoneService(programDomain: programDomain)
        initExtole()
        prefetch()
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
        doZoneRequest(zoneName: zoneName) { response, error in
            let campaignId = response?.header["x-extole-campaign"] ?? ""
            let zone = Zone(zoneName: zoneName, campaignId: Id(campaignId), content: response?.body?.data)
            let campaign = CampaignService(self.labels.joined(separator: ","), Id(campaignId), self.programDomain, zone,
                self.customHeaders, self.labels, self.data)
            completion(zone, campaign, error)
        }
    }

    private func doZoneRequest(zoneName: String, completion: @escaping (Response<ZoneResponse>?, Error?) -> Void) {
        var modifiedData = data
        modifiedData["labels"] = labels.joined(separator: ",")
        let requestBuilder = ZoneEndpoints.renderWithRequestBuilder(
            body: RenderZoneRequest(eventName: zoneName, data: modifiedData))

        httpCallFor(requestBuilder, programDomain + "/api", customHeaders)
            .execute { (response: Response<ZoneResponse>?, error: Error?) in
                completion(response, error)
            }
    }

    private func initExtole() {
        var accessToken = persistance.string(forKey: ACCESS_TOKEN_PREFERENCES_KEY) ?? ""
        let dispatchGroup = DispatchGroup()
        if accessToken.isEmpty {
            dispatchGroup.enter()
            AuthorizationEndpoints.createTokenWithRequestBuilder()
                .execute { [self] (token: Response<TokenResponse>?, _: Error?) in
                    accessToken = token?.body?.accessToken ?? ""
                    setAccessToken(accessToken: accessToken)
                    dispatchGroup.leave()
                }
        } else {
            setAccessToken(accessToken: accessToken)
        }
        dispatchGroup.notify(queue: .main) { [self] in
            setAccessToken(accessToken: accessToken)
        }
        dispatchGroup.wait()
    }

    private func setAccessToken(accessToken: String) {
        customHeaders["Authorization"] = "Bearer " + accessToken
        persistance.setValue(accessToken, forKey: ACCESS_TOKEN_PREFERENCES_KEY)
    }

    public func sendEvent(_ eventName: String, _ data: [String: Any?],
                          completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        self.data.forEach { key, value in
            customData[key] = value
        }
        let request = EventEndpoints.postWithRequestBuilder(body:
        SubmitEventRequest(eventName: eventName, data: customData.mapValues { value in
            value as! String
        }))
        httpCallFor(request, programDomain, customHeaders)
            .execute { [self] (response, error) in
                if response?.header["x-extole-token"] != nil {
                    setAccessToken(accessToken: response?.header["x-extole-token"] ?? "")
                }
                completion(response?.body?._id != nil ? Id(response?.body?._id ?? "") : nil, error)
            }
    }

    public func deleteAccessToken() {
        persistance.setNilValueForKey(ACCESS_TOKEN_PREFERENCES_KEY)
    }

    public func identify(_ identifier: String, _ data: [String: Any?],
                         _ completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        self.data.forEach { key, value in
            customData[key] = value
        }
        customData["email"] = identifier
        sendEvent("identify", customData, completion: completion)
    }

    public func getMe(_ completion: @escaping (Me, Error?) -> Void) {
        let requestBuilder = MeEndpoints.getMyProfileWithRequestBuilder()
        httpCallFor(requestBuilder, programDomain + "/api", customHeaders)
            .execute { (response: Response<MyProfileResponse>?, error: Error?) in
                let profile = response?.body
                completion(Me(email: profile?.email, firstName: profile?.firstName, lastName: profile?.lastName,
                    partnerUserId: profile?.partnerUserId, profilePictureUrl: profile?.profilePictureUrl), error)
            }
    }

    public func clone() -> ExtoleBuilder {
        ExtoleBuilderImpl(programDomain: programDomain, appName: appName, appData: appData,
            data: data, labels: labels, sandbox: sandbox, debugEnabled: debugEnabled)
    }

    public func webViewBuilder() -> ExtoleWebViewBuilder {
        ExtoleWebViewBuilderImpl(programDomain)
    }

}
