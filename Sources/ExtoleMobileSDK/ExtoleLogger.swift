import Foundation

public protocol ExtoleLogger {

    func setLogLevel(level: LogLevel)

    func getLogLevel() -> LogLevel

    func debug(_ message: String, args: Any?...)

    func info(_ message: String, args: Any?...)

    func warn(_ message: String, args: Any?...)

    func error(_ message: String, args: Any?...)

    func error(_ exception: Error, _ message: String, args: Any?...)
}

public enum LogLevel {
    case disable
    case debug
    case info
    case warn
    case error
}
