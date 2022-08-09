import Foundation
import ExtoleMobileSDK
import ObjectMapper

class CustomCondition: Condition {

    static var type: ConditionType = ConditionType.CUSTOM
    var customParameter: [String]? = []

    public init(customParameter: [String]) {
        super.init()
        self.customParameter = customParameter
    }

    public override init() {
        super.init()
    }

    public override func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        return customParameter?.contains(event.eventName) != nil
    }

    public override func getType() -> ConditionType {
        ConditionType.CUSTOM
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        customParameter <- map["custom_parameter"]
    }

    public var description: String { return "CustomCondition[customValue:\(customParameter)]" }
}
