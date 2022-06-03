import Foundation
import ObjectMapper

public class ExtoleOperation: Mappable {
    var actions: [Action] = []
    var conditions: [Condition] = []

    init(conditions: [Condition], actions: [Action]) {
        self.actions = actions
        self.conditions = conditions
    }

    public func executeActions(event: AppEvent, extole: ExtoleImpl) {
        actionsToExecute(event: event, extole: extole).forEach { action in
            action.execute(event: event, extole: extole)
        }
    }

    public func passingConditions(event: AppEvent, extole: ExtoleImpl) -> [Condition] {
        conditions.filter { condition in
            condition.passes(event: event, extole: extole)
        }
    }

    public func actionsToExecute(event: AppEvent, extole: ExtoleImpl) -> [Action] {
        if !conditions.isEmpty && passingConditions(event: event, extole: extole).count == conditions.count {
            return actions
        }
        return []
    }

    public required init?(map: Map) {
    }

    public func mapping(map: Map) {
        actions <- map["actions"]
        conditions <- map["conditions"]
    }
}
