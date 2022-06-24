import Foundation
import ExtoleMobileSDK
import ObjectMapper

public class CustomAction: Action {
    public static var type: ActionType = ActionType.CUSTOM

    var customActionValue: String?

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        extole.getLogger().setLogLevel(level: LogLevel.disable)
    }

    init(customActionValue: String) {
        super.init()
        self.customActionValue = customActionValue
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
        customActionValue <- map["custom_action_value"]
    }

    public var description: String {
        return "CustomAction[customActionValue:\(customActionValue)]"
    }
}
