import Foundation
import ExtoleConsumerAPI
import WebKit
import Logging
import SwiftEventBus
import SwiftUI
import CryptoKit
import ObjectMapper

public class ExtoleImpl: Extole {
    public var PARTNER_SHARE_ID_PREFRENCES_KEY: String = "partner_share_id"
    public var ACCESS_TOKEN_PREFERENCES_KEY: String = "access_token"
    public var EXTOLE_SDK_TAG: String = "EXTOLE"
    private let LOAD_OPERATIONS_ZONE: String = "mobile_bootstrap"
    private let APP_INITIALIZED_EVENT: String = "app_initialized"
    private let LOG_LEVEL: String = "log_level"
    private let ACCESS_TOKEN_HEADER_NAME = "x-extole-token"
    private let CAMPAIGN_ID_HEADER_NAME = "x-extole-campaign"
    private let APP_HEADER = "x-extole-app"
    private let APP_VERSION_HEADER = "x-extole-app-version"
    private let APP_TYPE_HEADER = "x-extole-app-type"
    private let APP_SHA_HEADER = "x-extole-app-sha"

    public var operations: [ExtoleOperation] = []
    public var zones: Zones = Zones()
    var programDomain: String
    var appName: String
    var appData: [String: String]
    var data: [String: String]
    var labels: [String]
    var customHeaders: [String: String] = [:]
    var observableUi = ExtoleObservableUi()

    private var sandbox: String
    private var personIdentifier: String?

    private let persistance: UserDefaults = UserDefaults.standard
    private var extoleServices: ExtoleServices?
    private var logger: ExtoleLogger
    private var engineInitialized = false
    private var app: App?
    private var logHandlers: [LogHandler] = []
    private var disabledActions: [ActionType] = []
    private var listenToEvents: Bool

    public init(programDomain: String, applicationName: String, personIdentifier: String? = nil,
                applicationData: [String: String] = [:], data: [String: String] = [:], labels: [String] = [],
                sandbox: String = "production-production", logHandlers: [LogHandler] = [],
                listenToEvents: Bool = true, disabledActions: [ActionType] = [],
                jwt: String? = nil) {
        self.programDomain = programDomain
        self.appName = applicationName
        self.appData = applicationData
        self.data = data
        self.labels = labels
        self.sandbox = sandbox
        self.personIdentifier = personIdentifier
        self.logHandlers = logHandlers
        self.listenToEvents = listenToEvents
        self.disabledActions = disabledActions

        var loggerContext: [String: String] = [:]
        loggerContext["tags"] = ["mobile-sdk"].joined(separator: ",")
        loggerContext["appName"] = appName
        loggerContext["programDomain"] = programDomain
        loggerContext["appData"] = applicationData.map { key, value -> String in
              key + "=" + value
          }
          .joined(separator: ",")
        self.logger = ExtoleLoggerImpl(programDomain, "", loggerContext, logHandlers)
        initAccessToken(email: personIdentifier, jwt: jwt) { [unowned self] (accessToken: String) in
            extoleServices = ExtoleServices(self)
            logger = ExtoleLoggerImpl(programDomain, accessToken, loggerContext, logHandlers)

            if listenToEvents {
                subscribe()
            }
        }
    }

    public func fetchZone(_ zoneName: String, _ data: [String: String], completion: @escaping (Zone?, Campaign?, Error?) -> Void) {
        let zoneKey = ZoneKey(zoneName, data.mapValues { $0 as Any? })
        let zoneResponse: Zone? = self.zones.getZone(for: zoneKey)
        if let zone = zoneResponse {
            let campaign = CampaignService(Id(zone.campaignId.value), zone, self)
            completion(zone, campaign, nil)
        } else {
            doZoneRequest(zoneName: zoneName, data: data) { [unowned self] response, error in
                if error != nil {
                    logger.error("""
                                 Failed to render zone=\(zoneName),
                                 data=\(data), errorCode=\(String(describing: error?.localizedDescription))
                                 """)
                }
                let campaignId = response?.body?.campaignId ?? ""
                let zone = Zone(zoneName: zoneName, campaignId: Id(campaignId), content: response?.body?.data, extole: self)
                let campaign = CampaignService(Id(campaignId), zone, self)
                self.zones.setZone(zone, for: zoneKey)
                completion(zone, campaign, error)
            }
        }
    }

    public func getServices() -> ExtoleServices {
        extoleServices ?? ExtoleServices(self)
    }

    public func sendEvent(_ eventName: String, _ data: [String: Any?],
                          _ completion: ((Id<Event>?, Error?) -> Void)?,
                          _ jwt: String? = nil) {
        var customData = data
        self.data.forEach { key, value in
            customData[key] = value
        }
        let request = EventEndpoints.postWithRequestBuilder(
          body: SubmitEventRequest(eventName: eventName, jwt: jwt, data: customData.mapValues { value in
              String(describing: value ?? "nil")
          }))
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        httpCallFor(request, self.programDomain, self.getHeaders())
          .execute { [self] (response, error) in
              if error != nil {
                  logger.error("""
                               Failed to send event=\(eventName),
                               data=\(data), error=\(String(describing: error?.localizedDescription))
                               """)
              }
              let accessTokenHeaderValue = response?.header[ACCESS_TOKEN_HEADER_NAME]
              if accessTokenHeaderValue != nil && accessTokenHeaderValue != getAccessToken() {
                  clearZonesCache()
                  setAccessToken(accessToken: accessTokenHeaderValue ?? "")
                  SwiftEventBus.post("access_token_changed", sender: AppEvent(eventName, data))
              }
              completion?(response?.body?._id != nil ? Id(response?.body?._id ?? "") : nil, error)
              dispatchGroup.leave()
          }
        dispatchGroup.wait(timeout: .now() + 5)
        SwiftEventBus.post("event", sender: AppEvent(eventName, data))
    }

    public func sendEvent(_ eventName: String, _ data: [String: Any?], _ completion: ((Id<Event>?, Error?) -> Void)?) {
        return sendEvent(eventName, data, completion, nil)
    }

    private func subscribe() {
        if !engineInitialized {
            let conditions: [Condition] = [EventCondition(eventNames: [APP_INITIALIZED_EVENT])]
            let actions: [Action] = [LoadOperationsAction(zones: [LOAD_OPERATIONS_ZONE])]
            self.app = App(extole: self)
            operations.append(ExtoleOperation(conditions: conditions, actions: actions))
            SwiftEventBus.post("event", sender: AppEvent("app_initialized", [:]))
            engineInitialized = true
            logger.debug("App initialized")
        }
    }

    public func getView() -> ExtoleView {
        ExtoleView(view: observableUi)
    }

    public func copy(programDomain: String? = nil, applicationName: String? = nil, email: String? = nil,
                     applicationData: [String: String]? = nil, data: [String: String]? = nil,
                     labels: [String]? = nil, sandbox: String? = nil, logHandlers: [LogHandler] = [],
                     listenToEvents: Bool = true, jwt: String? = nil) -> Extole {
        let extole = ExtoleImpl(programDomain: programDomain ?? self.programDomain, applicationName: applicationName ?? self.appName,
          personIdentifier: email ?? self.personIdentifier, data: data ?? self.data,
          labels: labels ?? self.labels, sandbox: sandbox ?? self.sandbox, logHandlers: logHandlers, listenToEvents: listenToEvents, jwt: jwt)
        app?.extole = extole
        return extole
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

    public func getLogger() -> ExtoleLogger {
        logger
    }

    public func getHeaders() -> [String: String] {
        var requestHeaders: [String: String] = [:]
        customHeaders.forEach { key, value in
            requestHeaders[key] = value
        }
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "1.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "1.0"
        let versionAndBuildNumber = "Version #\(versionNumber) (Build #\(buildNumber))"
        requestHeaders[APP_HEADER] = appName
        requestHeaders[APP_VERSION_HEADER] = versionAndBuildNumber
        requestHeaders[APP_TYPE_HEADER] = "mobile-sdk-ios"
        requestHeaders["Accept"] = "application/json"
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            requestHeaders[APP_SHA_HEADER] = sha256(bundleIdentifier)
        }
        return requestHeaders
    }

    public func identify(_ identifier: String, _ data: [String: Any?] = [:], _ completion: ((Id<Event>?, Error?) -> Void)?) {
        return self.identify(identifier, data, nil, completion)
    }

    private func identify(_ email: String?, _ data: [String: Any?], _ jwt: String?, _ completion: ((Id<Event>?, Error?) -> Void)?) {
        var customData = data
        self.data.forEach { key, value in
            customData[key] = value
        }
        if let identifier = email {
            customData["email"] = identifier
        }
        sendEvent("identify", customData, completion, jwt)
    }

    public func identifyJwt(_ jwt: String, _ data: [String: Any?] = [:], _ completion: ((Id<Event>?, Error?) -> Void)?) {
        sendEvent("identify", data, completion, jwt)
    }

    public func logout() {
        clearAccessToken()
        clearZonesCache()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        createAccessToken(email: "", jwt: nil, completion: { _ in }, dispatchGroup)
        _ = dispatchGroup.wait(timeout: .now() + 3.0)
    }

    public func getDisabledActions() -> [ActionType] {
        return disabledActions
    }

    public func getJsonConfiguration() -> String? {
        Mapper<ExtoleOperation>().toJSONString(operations)
    }

    public func getAccessToken() -> String? {
        return persistance.string(forKey: ACCESS_TOKEN_PREFERENCES_KEY)
    }

    private func initAccessToken(email: String?, jwt: String?, completion: @escaping (_ accessToken: String) -> Void) {
        let dispatchGroup = DispatchGroup()
        if email != nil || jwt != nil {
            clearAccessToken()
        }
        let accessToken = persistance.string(forKey: ACCESS_TOKEN_PREFERENCES_KEY) ?? ""
        dispatchGroup.enter()
        if accessToken.isEmpty {
            createAccessToken(email: email, jwt: jwt, completion: completion, dispatchGroup)
        } else {
            customHeaders["Authorization"] = "Bearer " + accessToken
            let request = AuthorizationEndpoints.getTokenDetailsWithRequestBuilder()
            httpCallFor(request, self.programDomain + "/api", self.getHeaders())
              .execute { [self] (_: Response<TokenResponse>?, error: Error?) in
                  if error != nil {
                      switch error as! ErrorResponse? {
                      case .error(403, _, _):
                          createAccessToken(email: email, jwt: jwt, completion: completion, dispatchGroup)
                      default:
                          dispatchGroup.leave()
                      }
                  } else {
                      setAccessToken(accessToken: accessToken, dispatchGroup)
                      completion(accessToken)
                  }
              }
        }
        _ = dispatchGroup.wait(timeout: .now() + 3.0)
    }

    private func toExtoleLogLevel(_ logLevel: String) -> LogLevel {
        switch logLevel {
        case "ERROR": return LogLevel.error
        case "WARN": return LogLevel.warn
        case "INFO": return LogLevel.info
        case "DEBUG": return LogLevel.debug
        case "DISABLE": return LogLevel.disable
        default: return LogLevel.error
        }
    }

    private func createAccessToken(email: String?, jwt: String?, completion: @escaping (_ accessToken: String) -> Void, _ dispatchGroup: DispatchGroup) {
        let request = AuthorizationEndpoints.createTokenWithRequestBuilder(body: CreateTokenRequest(jwt: jwt, email: email))
        httpCallFor(request, self.programDomain + "/api", self.customHeaders)
          .execute { [self] (tokenResponse: Response<TokenResponse>?, _: Error?) in
              let accessToken = tokenResponse?.body?.accessToken ?? ""
              setAccessToken(accessToken: accessToken, dispatchGroup)
              completion(accessToken)
          }
    }

    private func setAccessToken(accessToken: String, _ dispatchGroup: DispatchGroup? = nil) {
        logger.debug("Setting accessToken")
        customHeaders["Authorization"] = "Bearer " + accessToken
        persistance.setValue(accessToken, forKey: ACCESS_TOKEN_PREFERENCES_KEY)
        dispatchGroup?.leave()
    }

    private func clearAccessToken() {
        persistance.setValue("", forKey: ACCESS_TOKEN_PREFERENCES_KEY)
        customHeaders["Authorization"] = ""
    }

    private func clearZonesCache() {
        self.zones = Zones()
    }

    private func doZoneRequest(zoneName: String, data: [String: String], completion: @escaping (Response<ZoneResponse>?, Error?) -> Void) {
        var modifiedData: [String: String] = [:]
        data.forEach { (key: String, value: String) in
            modifiedData[key] = value
        }
        self.data.forEach { (key: String, value: String) in
            modifiedData[key] = value
        }
        if !labels.isEmpty {
            modifiedData["labels"] = labels.joined(separator: ",")
        }
        let requestBuilder = ZoneEndpoints.renderWithRequestBuilder(
          body: RenderZoneRequest(eventName: zoneName, data: modifiedData))

        httpCallFor(requestBuilder, self.programDomain + "/api", self.getHeaders())
          .execute { (response: Response<ZoneResponse>?, error: Error?) in
              completion(response, error)
          }
    }

}
