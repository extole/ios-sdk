import Foundation
import ObjectMapper

class NoOpCondition: Condition {

    static var type: ConditionType = ConditionType.NOT_DEFINED
    var data: [String: String]?

    public override init() {
        super.init()
    }

    public override func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        true
    }

    public override func getType() -> ConditionType {
        ConditionType.CUSTOM
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        data <- map["data"]
    }
}
