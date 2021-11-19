import Foundation

public protocol Campaign {

    func getProgram() -> String
    func getId() -> Id<Campaign>
    func getZone(_ zoneName: String, _ completion: @escaping (Zone?, Error?) -> Void)
    func emailShare(_ recipient: String, _ subject: String,
                    _ message: String, _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void)
    func sendEvent(_ eventName: String, _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void)
    func webViewBuilder() -> ExtoleWebViewBuilder
}
