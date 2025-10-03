import XCTest
import ExtoleMobileSDK
import ObjectMapper
import ExtoleConsumerAPI

class AppEngineTests: XCTestCase {
    
    func testOperationsAreDecoded() throws {
        let operationsJson = """
                                 [
                                   {
                                     "conditions": [
                                       {
                                         "type": "EVENT",
                                         "event_names": [
                                           "onAppOpen"
                                         ]
                                       }
                                     ],
                                     "actions": [
                                       {
                                         "type": "VIEW_FULLSCREEN",
                                         "zone_name": "welcome_offer"
                                       },
                                       {
                                         "type": "FETCH",
                                         "zones": [
                                           "mobile_menu"
                                         ],
                                         "data": {"key": "value"}
                                       },
                                       {
                                         "type": "SET_LOG_LEVEL",
                                         "log_level": "ERROR"
                                       }
                                     ]
                                   }
                                ]
                             """
        
        let operations = Mapper<ExtoleOperation>().mapArray(JSONString: operationsJson)
        
        XCTAssertEqual(operations?.count, 1)
        
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", applicationName: "appname")
        
        let passingConditions = operations?[0].passingConditions(event: AppEvent("onAppOpen"), extole: extole)
        XCTAssertEqual(passingConditions?.count, 1)
        XCTAssertEqual(passingConditions?[0].getType(), ConditionType.EVENT)
        
        let actionsToExecute = operations?[0].actionsToExecute(event: AppEvent("onAppOpen"), extole: extole)
        XCTAssertEqual(actionsToExecute?.count, 3)
        XCTAssertEqual(actionsToExecute?[0].getType(), ActionType.VIEW_FULLSCREEN)
        XCTAssertEqual(actionsToExecute?[1].getType(), ActionType.FETCH)
        XCTAssertEqual(actionsToExecute?[2].getType(), ActionType.SET_LOG_LEVEL)
        
        let viewFullscreenAction = actionsToExecute?[0] as! ViewFullScreenAction?
        XCTAssertEqual(viewFullscreenAction?.getZoneName(), "welcome_offer")
        
        let fetchAction = actionsToExecute?[1] as! FetchAction?
        XCTAssertEqual(fetchAction?.getZones(), ["mobile_menu"])
        XCTAssertEqual(fetchAction?.getData(), ["key": "value"])
        
        let setLogLevelAction = actionsToExecute?[2] as! SetLogLevelAction?
        XCTAssertEqual(setLogLevelAction?.getLogLevel(), "ERROR")
    }
    
    func testOperationsWithoutConditionsAreNotExecuted() {
        let operationsJson = """
                                 [
                                   {
                                     "conditions": [
                                     ],
                                     "actions": [
                                       {
                                         "type": "VIEW_FULLSCREEN",
                                         "zone_name": "welcome_offer"
                                       },
                                       {
                                         "type": "FETCH",
                                         "zones": [
                                           "mobile_menu"
                                         ],
                                         "data": {"key": "value"}
                                       },
                                       {
                                         "type": "SET_LOG_LEVEL",
                                         "log_level": "ERROR"
                                       }
                                     ]
                                   }
                                ]
                             """
        
        let operations = Mapper<ExtoleOperation>().mapArray(JSONString: operationsJson)
        
        XCTAssertEqual(operations?.count, 1)
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", applicationName: "appname")
        let actionsToExecute = operations?[0].actionsToExecute(event: AppEvent("onAppOpen"), extole: extole)
        XCTAssertEqual(actionsToExecute?.count, 0)
    }
    
    func testCustomActionAndConditionsAreDeserializedAndExecuted() throws {
        let operationsJson = """
                                 [
                                   {
                                     "conditions": [
                                       {
                                         "type": "CUSTOM_CONDITION",
                                         "custom_parameter": [
                                           "custom_value"
                                         ]
                                       },
                                       {
                                         "type": "CUSTOM",
                                         "data": {
                                           "key": "custom_value"
                                         }
                                       }
                                     ],
                                     "actions": [
                                       {
                                         "type": "CUSTOM_ACTION",
                                         "custom_parameter": "custom_value"
                                       },
                                       {
                                         "type": "CUSTOM",
                                          "data": {
                                            "key": "custom_value"
                                          }
                                       }
                                     ]
                                   }
                                 ]
                             """
        Action.customActionTypes["CUSTOM_ACTION"] = CustomAction()
        Condition.customConditionTypes["CUSTOM_CONDITION"] = CustomCondition()
        
        let operations = Mapper<ExtoleOperation>().mapArray(JSONString: operationsJson)
        XCTAssertEqual(operations?.count, 1)
        
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", applicationName: "appname")
        let passingConditions = operations?[0].passingConditions(event: AppEvent("custom_value"), extole: extole)
        XCTAssertEqual(passingConditions?.count, 2)
        XCTAssertEqual(passingConditions?[0].getType(), ConditionType.CUSTOM)
        XCTAssertEqual(passingConditions?[1].getType(), ConditionType.CUSTOM)
        
        let actionsToExecute = operations?[0].actionsToExecute(event: AppEvent("custom_value"), extole: extole)
        XCTAssertEqual(actionsToExecute?.count, 2)
        XCTAssertEqual(actionsToExecute?[0].getType(), ActionType.CUSTOM)
        XCTAssertEqual(actionsToExecute?[1].getType(), ActionType.CUSTOM)
        
        XCTAssertEqual(extole.getLogger().getLogLevel(), LogLevel.info)
        operations?[0].executeActions(event: AppEvent("custom_value"), extole: extole)
        XCTAssertEqual(extole.getLogger().getLogLevel(), LogLevel.disable)
    }
    
    func testConfiguredFlowIsExecuted() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
                                applicationName: "iOS App", labels: ["business"])
        
        let expectation = self.expectation(description: "Wait for Operations")
        DispatchQueue.global().async {
            let timeoutSeconds = 5
            for _ in 0...5 {
                print("There are \(extole.operations.count) operations")
                if extole.operations.count != 4 {
                    sleep(UInt32(timeoutSeconds))
                } else {
                    expectation.fulfill()
                    break
                }
            }
        }
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssertEqual(extole.operations.count, 4)
    }
    
    func testMobileMonitorOperationsAreExecutedAndLogLevelIsChanged() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
                                applicationName: "iOS App", labels: ["business"])
        
        let expectation = self.expectation(description: "Wait for Operations")
        DispatchQueue.global().async {
            let timeoutSeconds = 2
            for _ in 0...5 {
                print("Current log level \(extole.getLogger().getLogLevel())")
                if extole.getLogger().getLogLevel() != LogLevel.debug && extole.zones.getAllValues().count < 1 {
                    sleep(UInt32(timeoutSeconds))
                } else {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssertEqual(extole.getLogger().getLogLevel(), LogLevel.info)
        XCTAssertEqual(extole.zones.getAllValues().count, 1)
        
        let keys = extole.zones.getAllKeys()
            .sorted()
            .reduce(into: "") { (partialResult: inout String, key: ZoneKey) in
                partialResult.append("\(key),")
            }
        XCTAssertTrue(keys.hasPrefix("mobile_cta"))
    }
    
    func testOperationsAreConvertedToJson() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io",
                                applicationName: "iOS App", labels: ["business"])
        
        let expectation = self.expectation(description: "Wait for Operations")
        DispatchQueue.global().async {
            let timeoutSeconds = 2
            for _ in 0...5 {
                print("Current log level \(extole.getLogger().getLogLevel())")
                if extole.getLogger().getLogLevel() != LogLevel.debug && extole.zones.getAllValues().count < 1 {
                    sleep(UInt32(timeoutSeconds))
                } else {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssertEqual(extole.getLogger().getLogLevel(), LogLevel.info)
        XCTAssertEqual(extole.zones.getAllValues().count, 1)
        
        XCTAssertNotNil(extole.getJsonConfiguration())
    }
    
    func testCustomActionAndConditionsWithDataParametersAreDeserializedAndExecuted() throws {
        let operationsJson = """
                                 [
                                   {
                                     "conditions": [
                                       {
                                         "type": "CUSTOM_CONDITION",
                                         "data": {
                                           "key": "custom_value"
                                         }
                                       }
                                     ],
                                     "actions": [
                                       {
                                         "type": "CUSTOM_ACTION",
                                          "data": {
                                            "action": "set_log_level"
                                          }
                                       }
                                     ]
                                   }
                                 ]
                             """
        Action.customActionTypes["CUSTOM_ACTION"] = CustomActionWithDataParameters()
        Condition.customConditionTypes["CUSTOM_CONDITION"] = CustomConditionWithDataParameters()
        
        let operations = Mapper<ExtoleOperation>().mapArray(JSONString: operationsJson)
        XCTAssertEqual(operations?.count, 1)
        
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", applicationName: "appname")
        let passingConditions = operations?[0].passingConditions(event: AppEvent("custom_value"), extole: extole)
        XCTAssertEqual(passingConditions?.count, 1)
        XCTAssertEqual(passingConditions?[0].getType(), ConditionType.CUSTOM)
        
        let actionsToExecute = operations?[0].actionsToExecute(event: AppEvent("custom_value"), extole: extole)
        XCTAssertEqual(actionsToExecute?.count, 1)
        XCTAssertEqual(actionsToExecute?[0].getType(), ActionType.CUSTOM)
        
        XCTAssertEqual(extole.getLogger().getLogLevel(), LogLevel.info)
        operations?[0].executeActions(event: AppEvent("custom_value"), extole: extole)
        XCTAssertEqual(extole.getLogger().getLogLevel(), LogLevel.disable)
    }
    
    func testSendEventWithNonStringData() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", applicationName: "appname")
        let dataWithNonStringValues: [String: Any?] = [
            "stringValue": "test",
            "intValue": 42,
            "boolValue": true,
            "doubleValue": 3.14,
            "arrayValue": [1, 2, 3],
            "dictValue": ["nested": "value"],
            "nilValue": nil
        ]
        
        extole.sendEvent("testEvent", dataWithNonStringValues) { (eventId, error) in
            XCTAssertTrue(true, "sendEvent completed with non-String data")
            XCTAssertNotNil(eventId)
        }
    }
    
    func testZoneGetFlattenWithInvalidNestedPath() {
        let extole = ExtoleImpl(programDomain: "https://mobile-monitor.extole.io", applicationName: "appname")
        
        let mockContent: [String: Entry?] = [
            "simpleKey": try! Entry(from: MockStringDecoder())
        ]
        
        let zone = Zone(zoneName: "testZone", campaignId: Id("testCampaign"), content: mockContent, extole: extole)

        let simpleResult = zone.get("simpleKey")
        XCTAssertNotNil(simpleResult, "Expected non-nil result for simple path")
        let nestedResult = zone.get("simpleKey.nested")
        XCTAssertNil(nestedResult, "Expected nil for invalid nested path")
    }
}

class MockStringDecoder: Decoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        fatalError("Not implemented")
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("Not implemented")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return MockSingleValueContainer(value: "stringValue")
    }
}

class MockSingleValueContainer: SingleValueDecodingContainer {
    let value: String
    var codingPath: [CodingKey] = []
    
    init(value: String) {
        self.value = value
    }
    
    func decodeNil() -> Bool { return false }
    func decode(_ type: Bool.Type) throws -> Bool { return false }
    func decode(_ type: String.Type) throws -> String { return value }
    func decode(_ type: Double.Type) throws -> Double { return 0.0 }
    func decode(_ type: Float.Type) throws -> Float { return 0.0 }
    func decode(_ type: Int.Type) throws -> Int { 
        return Int(value) ?? value.hashValue
    }
    func decode(_ type: Int8.Type) throws -> Int8 { return 0 }
    func decode(_ type: Int16.Type) throws -> Int16 { return 0 }
    func decode(_ type: Int32.Type) throws -> Int32 { return 0 }
    func decode(_ type: Int64.Type) throws -> Int64 { return 0 }
    func decode(_ type: UInt.Type) throws -> UInt { return 0 }
    func decode(_ type: UInt8.Type) throws -> UInt8 { return 0 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return 0 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return 0 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return 0 }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if type == String.self {
            return value as! T
        }
        return String(describing: value) as! T
    }
}


