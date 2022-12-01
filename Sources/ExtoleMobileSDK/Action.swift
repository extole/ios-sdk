import Foundation
import ObjectMapper

open class Action: StaticMappable, Mappable {
    public static var customActionTypes: [String: Action] = [:]

    var type: ActionType?

    open func execute(event: AppEvent, extole: ExtoleImpl) {

    }

    open func getType() -> ActionType {
        ActionType.NOT_DEFINED
    }

    public init() {
    }

    public required init?(map: Map) {
    }

    open func mapping(map: Map) {
        type <- (map["type"], EnumTransform<ActionType>())
    }

    public static func objectForMapping(map: Map) -> BaseMappable? {
        let typeString: String? = map["type"].value()
        if let typeString = typeString {
            let actionType: ActionType? = ActionType(rawValue: typeString)
            if let actionType = actionType {
                switch actionType {
                case ActionType.FETCH: return FetchAction()
                case ActionType.LOAD_OPERATIONS: return LoadOperationsAction()
                case ActionType.VIEW_FULLSCREEN: return ViewFullScreenAction()
                case ActionType.PROMPT: return PromptAction()
                case ActionType.SET_LOG_LEVEL: return SetLogLevelAction()
                case ActionType.NATIVE_SHARE: return NativeShareAction()
                case ActionType.NOT_DEFINED: return NoOpAction()
                case ActionType.CUSTOM: return NoOpAction()
                }
            } else if Action.customActionTypes[typeString] != nil {
                return Action.customActionTypes[typeString]
            }
        }
        return Action()
    }
}
