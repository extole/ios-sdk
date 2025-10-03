import XCTest
import ExtoleMobileSDK
import ObjectMapper
import ExtoleConsumerAPI

class ExtoleMultithreadingTests: XCTestCase {
    
    func testConcurrentZonesResponseAccess() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", 
                                applicationName: "test-app")
        
        let expectation = self.expectation(description: "Concurrent access test")
        expectation.expectedFulfillmentCount = 5
        for i in 0..<5 {
            DispatchQueue.global(qos: .background).async {
                let data: [String: String] = [
                    "device_id": "test-device-\(i)",
                    "os": "iOS 15.0"
                ]
                extole.fetchZone("test_zone_\(i)", data) { zone, campaign, error in
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testZonesResponseThreadSafetyIssue() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", 
                                applicationName: "test-app")
        
        let expectation = self.expectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 3
        
        for i in 0..<3 {
            DispatchQueue.global(qos: .background).async {
                let data: [String: String] = [
                    "thread_id": "\(i)",
                    "timestamp": "\(Date().timeIntervalSince1970)"
                ]
                extole.fetchZone("race_zone_\(i)", data) { zone, campaign, error in
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
