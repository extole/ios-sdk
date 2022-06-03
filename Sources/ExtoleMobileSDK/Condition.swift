import Foundation
import ObjectMapper

public class Condition: StaticMappable, Mappable {

    var type: ConditionType?

    public func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        false
    }

    public func getType() -> ConditionType {
        ConditionType.EVENT
    }

    init() {
    }

    public required init?(map: Map) {
    }

    public func mapping(map: Map) {
        type <- (map["type"], EnumTransform<ConditionType>())
    }

    public static func objectForMapping(map: Map) -> BaseMappable? {
        let typeString: String? = map["type"].value()
        if let typeString = typeString {
            let actionType: ConditionType? = ConditionType(rawValue: typeString)
            if let actionType = actionType {
                switch actionType {
                case ConditionType.EVENT: return EventCondition()
                case ConditionType.NOT_DEFINED: return NoOpCondition()
                }
            }
        }
        return Condition()
    }
}
