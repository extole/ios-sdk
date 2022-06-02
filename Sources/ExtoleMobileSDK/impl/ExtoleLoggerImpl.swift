import Foundation
import Logging

class ExtoleLoggerImpl: ExtoleLogger {

    private var logger: Logger

    init(_ programDomain: String, _ accessToken: String, _ metadata: [String: String],
         _ logHandlers: [LogHandler] = []) {
        let metadataValues = metadata.mapValues({ value in Logger.MetadataValue(stringLiteral: value) })
        var customLogHandlers = logHandlers
        self.logger = Logger(label: "com.extole.mobile.sdk") { label in
            if customLogHandlers.isEmpty {
                customLogHandlers.append(StreamLogHandler.standardError(label: label))
                customLogHandlers.append(ExtoleLogHandler(programDomain, accessToken, metadataValues, label))
            }

            return MultiplexLogHandler(customLogHandlers)
        }
    }

    func setLogLevel(level: LogLevel) {
        let logLevel = mapToLibraryLogLevel(level: level)
        logger.logLevel = logLevel
    }

    func debug(_ message: String, args: Any?...) {
        logger.debug("\(message)")
    }

    func info(_ message: String, args: Any?...) {
        logger.info("\(message)")
    }

    func warn(_ message: String, args: Any?...) {
        logger.warning("\(message)")
    }

    func error(_ message: String, args: Any?...) {
        logger.error("\(message)")
    }

    func error(_ exception: Error, _ message: String, args: Any?...) {
        logger.error("\(exception) \(message)")
    }

    private func mapToLibraryLogLevel(level: LogLevel) -> Logger.Level {
        switch level {
        case .disable:
            return Logger.Level.critical
        case .info:
            return Logger.Level.info
        case .debug:
            return Logger.Level.debug
        case .warn:
            return Logger.Level.warning
        case .error:
            return Logger.Level.error
        }
    }

}
