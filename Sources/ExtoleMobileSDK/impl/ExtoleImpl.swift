import Foundation
import ExtoleConsumerAPI
import WebKit
import Logging
import SwiftEventBus
import SwiftUI

public class ExtoleImpl: Extole {
    public var PARTNER_SHARE_ID_PREFRENCES_KEY: String = "partner_share_id"
    public var ACCESS_TOKEN_PREFERENCES_KEY: String = "access_token"
    public var EXTOLE_SDK_TAG: String = "EXTOLE"
    private let PREFETCH_ZONE: String = "prefetch"
    private let LOG_LEVEL: String = "log_level"
    private let ACCESS_TOKEN_HEADER_NAME = "x-extole-token"
    private let CAMPAIGN_ID_HEADER_NAME = "x-extole-campaign"

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
    private var debugEnabled: Bool
    private var personIdentifier: String?

    private let zoneService: ZoneService
    private let persistance: UserDefaults = UserDefaults.standard
    private var logger: ExtoleLogger
    private var engineInitialized = false
    private var app: App?

    public init(programDomain: String, applicationName: String, personIdentifier: String? = nil,
                applicationData: [String: String] = [:], data: [String: String] = [:], labels: [String] = [],
                sandbox: String = "prod-prod", debugEnabled: Bool = false, logHandlers: [LogHandler] = [],
                listenToEvents: Bool = true) {
        self.programDomain = programDomain
        self.appName = applicationName
        self.appData = applicationData
        self.data = data
        self.labels = labels
        self.sandbox = sandbox
        self.debugEnabled = debugEnabled
        self.personIdentifier = personIdentifier

        var loggerContext: [String: String] = [:]
        loggerContext["tags"] = ["mobile-sdk"].joined(separator: ",")
        loggerContext["appName"] = appName
        loggerContext["programDomain"] = programDomain
        loggerContext["appData"] = applicationData.map { key, value -> String in
              key + "=" + value
          }
          .joined(separator: ",")
        self.logger = ExtoleLoggerImpl(programDomain, "", loggerContext, logHandlers)
        self.zoneService = ZoneService(programDomain: programDomain, logger: logger)
        initAccessToken { [unowned self] (accessToken: String) in
            logger = ExtoleLoggerImpl(programDomain, accessToken, loggerContext, logHandlers)
            logger.debug("Identifying with \(personIdentifier ?? "")")
            identify(personIdentifier) { (_, _) in
            }
            if listenToEvents {
                subscribe()
            }
        }
    }

    public func getZone(_ zoneName: String, completion: @escaping (Zone?, Campaign?, Error?) -> Void) {
        doZoneRequest(zoneName: zoneName) { [unowned self] response, error in
            if error != nil {
                logger.error("""
                             Failed to render zone=\(zoneName),
                             data=\(data), errorCode=\(String(describing: error?.localizedDescription))
                             """)
            }
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
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        httpCallFor(request, self.programDomain, self.customHeaders)
          .execute { [self] (response, error) in
              if error != nil {
                  logger.error("""
                               Failed to send event=\(eventName),
                               data=\(data), error=\(String(describing: error?.localizedDescription))
                               """)
              }
              if response?.header[ACCESS_TOKEN_HEADER_NAME] != nil {
                  setAccessToken(accessToken: response?.header[ACCESS_TOKEN_HEADER_NAME] ?? "")
              }
              completion(response?.body?._id != nil ? Id(response?.body?._id ?? "") : nil, error)
              dispatchGroup.leave()
          }
        dispatchGroup.wait(timeout: .now() + 5)
        SwiftEventBus.post("event", sender: AppEvent(eventName, data))
    }

    public func pollReward(pollingId: String, timeoutSeconds: Int = 5, retries: Int = 5, completion: @escaping (PollingRewardResponse?, Error?) -> Void) {
        let request = MeRewardEndpoints.getRewardStatusWithRequestBuilder(pollingId: pollingId)

        var rewardResponseWasReceived = false
        let dispatchGroup = DispatchGroup()
        for _ in 0...retries {
            dispatchGroup.enter()
            httpCallFor(request, self.programDomain + "/api", self.customHeaders)
              .execute { (pollingRewardResponse: Response<PollingRewardResponse>?, error: Error?) in
                  dispatchGroup.leave()
                  if pollingRewardResponse?.body?.status != PollingRewardResponse.Status.pending || error != nil {
                      rewardResponseWasReceived = true
                      return completion(pollingRewardResponse?.body, error)
                  }
              }
            sleep(UInt32(timeoutSeconds * 1_000_000))
            dispatchGroup.wait(timeout: .now() + 5)
        }
        if !rewardResponseWasReceived {
            logger.debug("reward response was not received")
            completion(nil, nil)
        }
    }

    private func subscribe() {
        if !engineInitialized {
            let conditions: [Condition] = [EventCondition(eventNames: ["app_initialized"])]
            let actions: [Action] = [LoadOperationsAction(zones: ["mobile_operations"])]
            self.app = App(extole: self)
            operations.append(ExtoleOperation(conditions: conditions, actions: actions))
            SwiftEventBus.post("event", sender: AppEvent("app_initialized", [:]))
            engineInitialized = true
        }
    }

    public func getView() -> ExtoleView {
        ExtoleView(view: observableUi)
    }

    public func copy(programDomain: String? = nil, applicationName: String? = nil, email: String? = nil,
                     applicationData: [String: String]? = nil, data: [String: String]? = nil,
                     labels: [String]? = nil, sandbox: String? = nil, debugEnabled: Bool? = nil,
                     logHandlers: [LogHandler] = [], listenToEvents: Bool = true) -> Extole {
        let extole = ExtoleImpl(programDomain: programDomain ?? self.programDomain, applicationName: applicationName ?? self.appName,
          personIdentifier: email ?? self.personIdentifier, data: data ?? self.data,
          labels: labels ?? self.labels, sandbox: sandbox ?? self.sandbox,
          debugEnabled: debugEnabled ?? self.debugEnabled, logHandlers: logHandlers, listenToEvents: listenToEvents)
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
        return customHeaders
    }

    private func identify(_ identifier: String?, _ data: [String: Any?] = [:],
                          _ completion: @escaping (Id<Event>?, Error?) -> Void) {
        var customData = data
        self.data.forEach { key, value in
            customData[key] = value
        }
        if identifier != nil {
            customData["email"] = identifier
            sendEvent("identify", customData, completion: completion)
        } else {
            completion(nil, nil)
        }
    }

    private func initAccessToken(completion: @escaping (_ accessToken: String) -> Void) {
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

    private func createAccessToken(completion: @escaping (_ accessToken: String) -> Void, _ dispatchGroup: DispatchGroup) {
        let request = AuthorizationEndpoints.createTokenWithRequestBuilder()
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
