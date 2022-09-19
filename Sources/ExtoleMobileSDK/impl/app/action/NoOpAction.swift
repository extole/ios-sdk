import Foundation
import ObjectMapper

public class NoOpAction: Action {
    public static var type: ActionType = ActionType.NOT_DEFINED
    var data: [String: String]?
    var actionType: String = type.rawValue

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
    }

    override init() {
        super.init()
    }

    public override func getType() -> ActionType {
        ActionType.CUSTOM
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        data <- map["data"]
        actionType <- map["type"]
    }
}
