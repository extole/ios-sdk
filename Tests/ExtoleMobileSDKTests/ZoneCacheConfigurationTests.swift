import XCTest
@testable import ExtoleMobileSDK
import ExtoleConsumerAPI

class ZoneCacheConfigurationTests: XCTestCase {

    func testZonesCacheEnabledDefaultsToTrue() {
        let extole = ExtoleImpl(
            programDomain: "https://mobile-monitor.extole.io",
            applicationName: "appname",
            listenToEvents: false
        )
        XCTAssertTrue(extole.isZonesCacheEnabled(), "zonesCacheEnabled should default to true")
    }

    func testZonesCacheEnabledFalseViaConstructor() {
        let extole = ExtoleImpl(
            programDomain: "https://mobile-monitor.extole.io",
            applicationName: "appname",
            listenToEvents: false,
            zonesCacheEnabled: false
        )
        XCTAssertFalse(extole.isZonesCacheEnabled(), "zonesCacheEnabled should be false when passed in init")
    }

    func testZonesCacheEnabledTrueViaConstructor() {
        let extole = ExtoleImpl(
            programDomain: "https://mobile-monitor.extole.io",
            applicationName: "appname",
            listenToEvents: false,
            zonesCacheEnabled: true
        )
        XCTAssertTrue(extole.isZonesCacheEnabled(), "zonesCacheEnabled should be true when explicitly passed")
    }

    func testCopyPreservesZonesCacheEnabled() {
        let extole = ExtoleImpl(
            programDomain: "https://mobile-monitor.extole.io",
            applicationName: "appname",
            listenToEvents: false,
            zonesCacheEnabled: false
        )
        let copy = extole.copy() as? ExtoleImpl
        XCTAssertNotNil(copy, "copy() should return ExtoleImpl")
        XCTAssertFalse(copy?.isZonesCacheEnabled() ?? true, "copy() should preserve zonesCacheEnabled false")
    }

    func testCopyPreservesZonesCacheEnabledWhenTrue() {
        let extole = ExtoleImpl(
            programDomain: "https://mobile-monitor.extole.io",
            applicationName: "appname",
            listenToEvents: false,
            zonesCacheEnabled: true
        )
        let copy = extole.copy() as? ExtoleImpl
        XCTAssertNotNil(copy)
        XCTAssertTrue(copy?.isZonesCacheEnabled() ?? false, "copy() should preserve zonesCacheEnabled true")
    }

    func testFetchZoneWithCacheDisabledDoesNotStoreInCache() {
        let expectation = self.expectation(description: "fetchZone completion")
        let extole = ExtoleImpl(
            programDomain: "https://mobile-monitor.extole.io",
            applicationName: "iOS App",
            listenToEvents: false,
            zonesCacheEnabled: false
        )
        let zoneName = "mobile_cta"
        let data: [String: String] = [:]
        let zoneKey = ZoneKey(zoneName, data.mapValues { $0 as Any? })

        extole.fetchZone(zoneName, data) { _, _, _ in
            let cached = extole.zones.getZone(for: zoneKey)
            XCTAssertNil(cached, "With cache disabled, fetchZone should not store the zone in cache")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSetZonesCacheEnabledFromBootstrapConfiguration() {
        let extole = ExtoleImpl(
            programDomain: "https://mobile-monitor.extole.io",
            applicationName: "appname",
            listenToEvents: false
        )
        XCTAssertTrue(extole.isZonesCacheEnabled())

        extole.setZonesCacheEnabled(false)
        XCTAssertFalse(extole.isZonesCacheEnabled(), "setZonesCacheEnabled(false) should disable cache")

        extole.setZonesCacheEnabled(true)
        XCTAssertTrue(extole.isZonesCacheEnabled(), "setZonesCacheEnabled(true) should enable cache")
    }
}
