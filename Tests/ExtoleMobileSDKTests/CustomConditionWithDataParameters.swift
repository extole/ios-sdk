import Foundation
import ExtoleMobileSDK
import ObjectMapper

class CustomConditionWithDataParameters: Condition {

    static var type: ConditionType = ConditionType.CUSTOM
    var data: [String: String]? = [:]

    public init(data: [String: String]) {
        super.init()
        self.data = data
    }

    public override init() {
        super.init()
    }

    public override func passes(event: AppEvent, extole: ExtoleImpl) -> Bool {
        return self.data?["key"] == "custom_value"
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

    public var description: String { return "CustomCondition[data:\(data)]" }
}
