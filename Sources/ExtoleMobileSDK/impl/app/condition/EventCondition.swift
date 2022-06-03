import Foundation
import ObjectMapper

class EventCondition: Condition {
    static var type: ConditionType = ConditionType.EVENT
    var eventNames: [String]? = []

    public init(eventNames: [String]) {
        super.init()
        self.eventNames = eventNames
    }

    public override init() {
        super.init()
    }

    public override func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        let evaluationResult = !(eventNames?.filter({ eventName in
                eventName == event.eventName
            })
            .isEmpty ?? false)
        extole.getLogger().debug("""
                                  Evaluating EventCondition=\(eventNames ?? []), event=\(event.eventName),
                                  evaluationResult=\(evaluationResult)
                                  """)
        return evaluationResult
    }

    public override func getType() -> ConditionType {
        ConditionType.EVENT
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        eventNames <- map["event_names"]
    }
}
