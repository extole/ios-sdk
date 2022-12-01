import Foundation
import ExtoleConsumerAPI
import SwiftEventBus

public protocol ShareService {

    func emailShare(_ recipient: String, _ subject: String, _ message: String,
                    _ data: [String: Any?], _ completion: @escaping (Id<Event>?, Error?) -> Void)
}
