import Foundation
import WebKit

public protocol Extole {

    func getZone(_ zoneName: String, completion: @escaping (Zone?, Campaign?, Error?) -> Void)

    func sendEvent(_ eventName: String, _ data: [String: Any?], completion: @escaping (Id<Event>?, Error?) -> Void)

    func deleteAccessToken()

    func identify(_ identifier: String, _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void)

    func getMe(_ completion: @escaping (Me, Error?) -> Void)

    func clone() -> ExtoleBuilder

    func webViewBuilder() -> ExtoleWebViewBuilder

    var EXTOLE_SDK_TAG: String { get }
    var ACCESS_TOKEN_PREFERENCES_KEY: String { get }
    var PARTNER_SHARE_ID_PREFRENCES_KEY: String { get }
}
