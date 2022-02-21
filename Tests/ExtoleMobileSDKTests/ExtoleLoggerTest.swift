import XCTest
import Logging

@testable import ExtoleMobileSDK

final class ExtoleLoggerTest: XCTestCase {

    var inMemoryLogs: [Logger.Level: [String]] = [:]
    var logger: ExtoleLogger?
    override func setUpWithError() throws {
        let logHandler = ExtoleLogHandler("program-domain", "access-token", [:], "extole", { [self] message, level in
            if inMemoryLogs[level] == nil {
                inMemoryLogs[level] = []
            }
            inMemoryLogs[level]?.append(message)
        })
        logger = ExtoleLoggerImpl("program-domain", "access-token", [:], [logHandler])
    }

    func testAllErrorsAreLoggedWithLevelDebug() throws {
        logger?.setLogLevel(level: .debug)

        logger?.debug("Debug")
        logger?.info("Info")
        logger?.warn("Warn")
        logger?.error("Error")

        XCTAssert(inMemoryLogs[Logger.Level.debug]?.count == 1)
        XCTAssertEqual(inMemoryLogs[Logger.Level.debug]![0], "extole : Debug\n")

        XCTAssert(inMemoryLogs[Logger.Level.info]?.count == 1)
        XCTAssertEqual(inMemoryLogs[Logger.Level.info]![0], "extole : Info\n")

        XCTAssert(inMemoryLogs[Logger.Level.warning]?.count == 1)
        XCTAssertEqual(inMemoryLogs[Logger.Level.warning]![0], "extole : Warn\n")

        XCTAssert(inMemoryLogs[Logger.Level.error]?.count == 1)
        XCTAssertEqual(inMemoryLogs[Logger.Level.error]![0], "extole : Error\n")
    }

    func testOnlyWarnAndErrorAreLoggedWithLevelWarn() throws {
        logger?.setLogLevel(level: .warn)

        logger?.debug("Debug")
        logger?.info("Info")
        logger?.warn("Warn")
        logger?.error("Error")

        XCTAssert(inMemoryLogs[Logger.Level.debug] == nil)
        XCTAssert(inMemoryLogs[Logger.Level.info] == nil)

        XCTAssert(inMemoryLogs[Logger.Level.warning]?.count == 1)
        XCTAssertEqual(inMemoryLogs[Logger.Level.warning]![0], "extole : Warn\n")

        XCTAssert(inMemoryLogs[Logger.Level.error]?.count == 1)
        XCTAssertEqual(inMemoryLogs[Logger.Level.error]![0], "extole : Error\n")
    }

    func testNoErrorsAreLoggedWhenLogLevelIsDisable() throws {
        logger?.setLogLevel(level: .disable)

        logger?.debug("Debug")
        logger?.info("Info")
        logger?.warn("Warn")
        logger?.error("Error")

        XCTAssert(inMemoryLogs[Logger.Level.debug] == nil)
        XCTAssert(inMemoryLogs[Logger.Level.info] == nil)
        XCTAssert(inMemoryLogs[Logger.Level.warning] == nil)
        XCTAssert(inMemoryLogs[Logger.Level.error] == nil)
    }

    func testOnlyErrorsAreLoggedByDefault() throws {
        logger?.debug("Debug")
        logger?.info("Info")
        logger?.warn("Warn")
        logger?.error("Error")

        XCTAssert(inMemoryLogs[Logger.Level.debug] == nil)
        XCTAssert(inMemoryLogs[Logger.Level.info] == nil)
        XCTAssert(inMemoryLogs[Logger.Level.warning] == nil)

        XCTAssert(inMemoryLogs[Logger.Level.error]?.count == 1)
        XCTAssertEqual(inMemoryLogs[Logger.Level.error]![0], "extole : Error\n")
    }
}
