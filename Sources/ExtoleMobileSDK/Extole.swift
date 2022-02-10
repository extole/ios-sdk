import Foundation
import WebKit
import Logging

public protocol Extole {

    func getZone(_ zoneName: String, completion: @escaping (Zone?, Campaign?, Error?) -> Void)

    func sendEvent(_ eventName: String, _ data: [String: Any?], completion: @escaping (Id<Event>?, Error?) -> Void)

    func webView(headers: [String: String], data: [String: String]) -> ExtoleWebView

    func getLogger() -> ExtoleLogger?

    func copy(programDomain: String?, applicationName: String?, email: String?, applicationData: [String: String]?,
              data: [String: String]?, labels: [String]?, sandbox: String?, debugEnabled: Bool?, logHandlers: [LogHandler]) -> Extole

    var EXTOLE_SDK_TAG: String { get }
    var ACCESS_TOKEN_PREFERENCES_KEY: String { get }
    var PARTNER_SHARE_ID_PREFRENCES_KEY: String { get }
}

extension Extole {
    public func copy(programDomain: String? = nil, applicationName: String? = nil, email: String? = nil,
                     applicationData: [String: String]? = nil, data: [String: String]? = nil,
                     labels: [String]? = nil, sandbox: String? = nil, debugEnabled: Bool? = nil, logHandlers: [LogHandler] = []) -> Extole {
        return copy(programDomain: programDomain, applicationName: applicationName, email: email,
            applicationData: applicationData, data: data, labels: labels, sandbox: sandbox, debugEnabled: debugEnabled, logHandlers: logHandlers)
    }

    public func webView(headers: [String: String] = [:], data: [String: String] = [:]) -> ExtoleWebView {
        return webView(headers: headers, data: data)
    }
}
