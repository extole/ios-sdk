import Foundation
import Logging
import ExtoleConsumerAPI

struct ExtoleLogHandler: LogHandler {

    private var prettyMetadata: String?
    private var label: String
    private var loggingMethod: (String, Logger.Level) -> Void

    public var logLevel: Logger.Level = .error

    init(_ programDomain: String, _ accessToken: String, _ metadata: [String: Logger.MetadataValue],
         _ label: String, _ loggingMethod: ((String, Logger.Level) -> Void)? = nil) {
        var customHeaders: [String: String] = [:]
        customHeaders["Authorization"] = "Bearer " + accessToken
        self.metadata = metadata
        self.label = label
        self.loggingMethod = loggingMethod ?? { logMessage, level in
            doLogging(logMessage: logMessage, level: level, programDomain: programDomain, customHeaders: customHeaders)
        }
        self.prettyMetadata = prettify(metadata)
    }

    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = prettify(metadata)
        }
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set {
            metadata[metadataKey] = newValue
        }
    }

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        let prettyMetadata = metadata?.isEmpty ?? true
          ? prettyMetadata
          : prettify(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))
        if logLevel != .critical { // Loggger.Level.critical is considered .disable in ExtoleSdk
            let logMessage = "\(self.label) :\(prettyMetadata.map { " \($0)" } ?? "") \(message)\n"
            loggingMethod(logMessage, level)
        }
    }

    private func prettify(_ metadata: Logger.Metadata) -> String? {
        !metadata.isEmpty
          ? metadata.lazy.sorted(by: { $0.key < $1.key }).map {
              "\($0)=\($1)"
          }
          .joined(separator: ",")
          : nil
    }
}

func doLogging(logMessage: String, level: Logger.Level, programDomain: String, customHeaders: [String: String]) {
    let creativeLoggerRequest = CreativeLoggingEndpoints
      .createWithRequestBuilder(body: CreateCreativeLogRequest(message: logMessage, level: toCreativeLogLevel(level: level)))
    httpCallFor(creativeLoggerRequest, programDomain + "/api", customHeaders).execute { _, error in
        if error != nil {
            NSLog("Failed to send logs" + error.debugDescription)
        }
    }
}

func toCreativeLogLevel(level: Logger.Level) -> CreateCreativeLogRequest.Level {
    switch level {
    case Logger.Level.info: return CreateCreativeLogRequest.Level.info
    case .trace: return CreateCreativeLogRequest.Level.debug
    case .debug: return CreateCreativeLogRequest.Level.debug
    case .notice: return CreateCreativeLogRequest.Level.debug
    case .warning: return CreateCreativeLogRequest.Level.warn
    case .error: return CreateCreativeLogRequest.Level.error
    case .critical: return CreateCreativeLogRequest.Level.error
    }
}
