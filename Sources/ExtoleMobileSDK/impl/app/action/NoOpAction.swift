import Foundation
import ObjectMapper

public class NoOpAction: Action {
    public static var type: ActionType = ActionType.NOT_DEFINED

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
    }

    override init() {
        super.init()
    }

    public override func getType() -> ActionType {
        ActionType.NOT_DEFINED
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
    }
}
