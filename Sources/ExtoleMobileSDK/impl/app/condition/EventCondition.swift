import Foundation
import ObjectMapper

class EventCondition: Condition, CustomStringConvertible {
    static var type: ConditionType = ConditionType.EVENT
    var eventNames: [String]? = []
    var hasDataKeys: [String]? = []
    var hasDataValues: [String]? = []
    var conditionType: String = type.rawValue

    public init(eventNames: [String], hasDataKeys: [String] = [], hasDataValues: [String] = []) {
        super.init()
        self.eventNames = eventNames
        self.hasDataKeys = hasDataKeys
        self.hasDataValues = hasDataValues
    }

    public override init() {
        super.init()
    }

    public override func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        let eventNameMatches = !(eventNames?.filter({ eventName in
                eventName == event.eventName
            })
            .isEmpty ?? false)
        let keyMatches = hasDataKeys == nil || (hasDataKeys ?? []).isEmpty || ((hasDataKeys ?? []).contains(where: { key in
            event.eventData.contains { (eventDataKey: String, _: Any?) in
                eventDataKey.range(of: key, options: .regularExpression) != nil
            }
        }))
        let valueMatches = hasDataValues == nil || (hasDataValues ?? []).isEmpty || (hasDataValues ?? []).contains(where: { value in
            event.eventData.contains { (_: String, eventDataValue: Any?) in
                (eventDataValue as? String)?.range(of: value, options: .regularExpression) != nil
            }
        })
        let passes = eventNameMatches && keyMatches && valueMatches
        extole.getLogger().debug("""
                                  Evaluating \(self), event=\(event),
                                  evaluationResult=\(passes)
                                  """)
        return passes
    }

    public override func getType() -> ConditionType {
        ConditionType.EVENT
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        eventNames <- map["event_names"]
        hasDataKeys <- map["has_data_keys"]
        hasDataValues <- map["has_data_values"]
        conditionType <- map["type"]
    }

    public var description: String { return "EventCondition[eventNames:\(eventNames), hasDataKeys:\(hasDataKeys), hasDataValue:\(hasDataValues)]" }
}
