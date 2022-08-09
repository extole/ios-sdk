import Foundation
import ObjectMapper

public class SetLogLevelAction: Action, CustomStringConvertible {
    public static var type: ActionType = ActionType.SET_LOG_LEVEL

    var logLevel: String?

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        extole.getLogger().debug("SetLogLevelAction, event=\(event)")
        extole.getLogger().setLogLevel(level: toExtoleLogLevel(logLevel: logLevel))
    }

    private func toExtoleLogLevel(logLevel: String?) -> LogLevel {
        switch logLevel {
        case "ERROR":
            return LogLevel.error
        case "WARN":
            return LogLevel.warn
        case "INFO":
            return LogLevel.info
        case "DEBUG":
            return LogLevel.debug
        default:
            return LogLevel.error
        }
    }

    init(logLevel: String) {
        super.init()
        self.logLevel = logLevel
    }

    override init() {
        super.init()
    }

    public func getLogLevel() -> String? {
        logLevel
    }

    public override func getType() -> ActionType {
        ActionType.SET_LOG_LEVEL
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        logLevel <- map["log_level"]
    }

    public var description: String { return "SetLogLevel[logLevel:\(logLevel)]" }
}
