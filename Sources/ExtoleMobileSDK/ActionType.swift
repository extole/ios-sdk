import Foundation

public enum ActionType: String, Decodable {
    case NOT_DEFINED
    case VIEW_FULLSCREEN
    case PROMPT
    case SET_LOG_LEVEL
    case FETCH
    case LOAD_OPERATIONS
    case NATIVE_SHARE
}
