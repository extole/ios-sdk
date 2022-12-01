import Foundation
import ExtoleMobileSDK
import ObjectMapper

public class CustomActionWithDataParameters: Action {
    public static var type: ActionType = ActionType.CUSTOM

    var data: [String: String]? = [:]

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        if data?["action"] == "set_log_level" {
            extole.getLogger().setLogLevel(level: LogLevel.disable)
        }
    }

    init(data: [String: String]) {
        super.init()
        self.data = data
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
    }

    public var description: String {
        return "CustomActionWithDataParameters[data:\(data)]"
    }
}
