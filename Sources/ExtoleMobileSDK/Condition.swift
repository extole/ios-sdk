import Foundation
import ObjectMapper

open class Condition: StaticMappable, Mappable {
    public static var customConditionTypes: [String: Condition] = [:]
    var type: ConditionType?

    open func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        false
    }

    open func getType() -> ConditionType {
        ConditionType.EVENT
    }

    public init() {
    }

    public required init?(map: Map) {
    }

    open func mapping(map: Map) {
        type <- (map["type"], EnumTransform<ConditionType>())
    }

    public static func objectForMapping(map: Map) -> BaseMappable? {
        let typeString: String? = map["type"].value()
        if let typeString = typeString {
            let conditionType: ConditionType? = ConditionType(rawValue: typeString)
            if let conditionType = conditionType {
                switch conditionType {
                case ConditionType.EVENT: return EventCondition()
                case ConditionType.NOT_DEFINED: return NoOpCondition()
                case ConditionType.CUSTOM: return NoOpCondition()
                }
            } else if Condition.customConditionTypes[typeString] != nil {
                return Condition.customConditionTypes[typeString]
            }
        }
        return Condition()
    }
}
