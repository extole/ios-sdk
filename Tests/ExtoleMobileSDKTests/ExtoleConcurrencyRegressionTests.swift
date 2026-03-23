import Foundation
import XCTest
@testable import ExtoleMobileSDK

final class ExtoleConcurrencyRegressionTests: XCTestCase {

    func testConcurrentCampaignCreationAndStateReadsDoesNotCrash() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
                                applicationName: "test-app",
                                listenToEvents: false)
        let expectation = expectation(description: "Concurrent campaign creation and state reads")
        expectation.expectedFulfillmentCount = 200

        for i in 0..<200 {
            DispatchQueue.global(qos: .userInitiated).async {
                let campaignId = "campaign_\(i % 10)"
                let zone = Zone(zoneName: "seed_zone_\(i)",
                                campaignId: Id(campaignId),
                                content: [:],
                                extole: extole)
                let campaign = CampaignService(Id(campaignId), zone, extole)
                _ = campaign.getId()
                _ = extole.dataSnapshot()
                _ = extole.getHeaders()
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 20.0)
    }

    func testCampaignServiceInitDoesNotMutateGlobalData() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
                                applicationName: "test-app",
                                data: ["base_key": "base_value"],
                                listenToEvents: false)
        let beforeSnapshot = extole.dataSnapshot()
        let zone = Zone(zoneName: "seed_zone",
                        campaignId: Id("campaign_A"),
                        content: [:],
                        extole: extole)

        _ = CampaignService(Id("campaign_A"), zone, extole)
        let afterSnapshot = extole.dataSnapshot()

        XCTAssertEqual(beforeSnapshot, afterSnapshot)
        XCTAssertNil(afterSnapshot["campaign_id"])
    }

    func testCampaignTargetIsRequestLocalAndNotGlobal() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
                                applicationName: "test-app",
                                data: ["shared": "value"],
                                listenToEvents: false)
        extole.skipSendEventNetworkForTests = true
        let zoneA = Zone(zoneName: "zone_A", campaignId: Id("campaign_A"), content: [:], extole: extole)
        let zoneB = Zone(zoneName: "zone_B", campaignId: Id("campaign_B"), content: [:], extole: extole)
        let campaignA = CampaignService(Id("campaign_A"), zoneA, extole)
        let campaignB = CampaignService(Id("campaign_B"), zoneB, extole)

        let lock = NSLock()
        var capturedTargets: [String] = []
        extole.sendEventObserver = { _, payload in
            if let target = payload["target"] as? String {
                lock.lock()
                capturedTargets.append(target)
                lock.unlock()
            }
        }

        let group = DispatchGroup()
        for i in 0..<100 {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                campaignA.sendEvent("share", ["seq": i], nil)
                group.leave()
            }
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                campaignB.sendEvent("share", ["seq": i], nil)
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 10.0), .success)
        XCTAssertEqual(capturedTargets.count, 200)
        XCTAssertEqual(capturedTargets.filter { $0 == "campaign_id:campaign_A" }.count, 100)
        XCTAssertEqual(capturedTargets.filter { $0 == "campaign_id:campaign_B" }.count, 100)
        XCTAssertNil(extole.dataSnapshot()["campaign_id"])
        XCTAssertEqual(extole.dataSnapshot()["shared"], "value")
    }

    func testConcurrentCustomHeaderUpdatesAndHeaderSnapshotsAreConsistent() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
                                applicationName: "test-app",
                                listenToEvents: false)
        let group = DispatchGroup()
        let lock = NSLock()
        var hasInvalidHeaders = false

        for i in 0..<200 {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                extole.setCustomHeader("Authorization", value: "Bearer token-\(i)")
                group.leave()
            }
        }

        for _ in 0..<400 {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let headers = extole.getHeaders()
                let isValid = headers["Accept"] == "application/json"
                    && headers["x-extole-app-type"] == "mobile-sdk-ios"
                    && headers["x-extole-app"] == "test-app"

                if !isValid {
                    lock.lock()
                    hasInvalidHeaders = true
                    lock.unlock()
                }
                group.leave()
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 10.0), .success)
        XCTAssertFalse(hasInvalidHeaders)
    }
}
