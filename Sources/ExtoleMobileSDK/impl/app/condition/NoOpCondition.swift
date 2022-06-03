import Foundation
import ObjectMapper

class NoOpCondition: Condition {

    static var type: ConditionType = ConditionType.NOT_DEFINED

    public override init() {
        super.init()
    }

    public override func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        false
    }

    public override func getType() -> ConditionType {
        ConditionType.NOT_DEFINED
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
    }
}
