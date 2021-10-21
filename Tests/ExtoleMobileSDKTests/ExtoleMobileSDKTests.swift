import XCTest

@testable import ExtoleMobileSDK

final class ExtoleMobileSDKTests: XCTestCase {
    func testExtole() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        XCTAssertEqual(Extole().helloExtole(), "Extole")
    }

    func testCampaign() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        XCTAssertEqual(Campaign().helloCampaign(), "Campaign")
    }
}
