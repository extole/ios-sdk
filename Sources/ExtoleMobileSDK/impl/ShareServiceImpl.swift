import Foundation

class ShareServiceImpl: ShareService {

    let extole: ExtoleImpl

    init(_ extole: ExtoleImpl) {
        self.extole = extole
    }

    public func emailShare(_ recipient: String, _ subject: String, _ message: String,
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

        extole.sendEvent("share", customData, completion: completion)
    }
}
