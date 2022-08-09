import Foundation

public class AppEvent: CustomStringConvertible {
    public let eventName: String
    public let eventData: [String: Any?]

    public init(_ eventName: String, _ eventData: [String: Any?] = [:]) {
        self.eventName = eventName
        self.eventData = eventData
    }

    public var description: String { return "AppEvent[eventName:\(eventName), eventData:\(eventData)]" }
}
