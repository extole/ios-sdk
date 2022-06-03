import Foundation

public class AppEvent: CustomStringConvertible {
    let eventName: String
    let eventData: [String: Any?]

    public init(_ eventName: String, _ eventData: [String: Any?] = [:]) {
        self.eventName = eventName
        self.eventData = eventData
    }

    public var description: String { return "AppEvent[eventName:\(eventName), eventData:\(eventData)]" }
}
