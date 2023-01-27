import Foundation
import ObjectMapper
import ExtoleConsumerAPI
import SwiftEventBus

public class LoadOperationsAction: Action, Hashable, Equatable, CustomStringConvertible {

    public static var type: ActionType = ActionType.LOAD_OPERATIONS

    var zones: [String]?
    var data: [String: String]?
    var actionType: String = type.rawValue
    private var zoneFetcher: ZoneFetcher?

    private static var loadOperationActions = Set<LoadOperationsAction>()

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        removeExecutedActionsFromQueue()

        extole.getLogger().debug("LoadOperationsAction, event=\(event.eventName)")
        let allData = prepareRequestData(extole: extole)

        zoneFetcher = ZoneFetcher(programDomain: extole.programDomain, logger: extole.getLogger(), extole: extole)

        zoneFetcher?.getZones(zonesName: zones ?? [], data: allData,
            programLabels: extole.labels, customHeaders: extole.getHeaders()) { [self] response in
            response.forEach({ (_: ZoneResponseKey, value: Zone?) in
                let operationsJson = value?.get("operations") as? [Entry?]
                if value?.get("operations") != nil {
                    let json = try! JSONEncoder().encode(operationsJson)
                    let jsonString = String(data: json, encoding: .utf8)!
                    let operations = Mapper<ExtoleOperation>().mapArray(JSONString: jsonString)
                    operations?.forEach({ operation in
                        extole.operations.append(operation)
                    })
                    addAdditionalLoadOperationsToTheQueue(operations: operations)

                    extole.getLogger().debug("Executing, operations=\(operations ?? [])")
                    AppEngine(operations ?? []).execute(event: AppEvent("on_load"), extole: extole)
                }
            })

            if LoadOperationsAction.loadOperationActions.isEmpty {
                SwiftEventBus.post("event", sender: AppEvent(AppEngine.LOAD_DONE_EVENT, [:]))
            }
        }
    }

    private func addAdditionalLoadOperationsToTheQueue(operations: [ExtoleOperation]?) {
        let actions: [Action]? = operations?.flatMap({ operation in
            operation.actions
        })
        let additionalLoadOperations = actions?.filter { action in
            action.getType() == ActionType.LOAD_OPERATIONS
            }
            .map { action -> LoadOperationsAction in
                action as! LoadOperationsAction
            }
        additionalLoadOperations?.forEach({ action in
            LoadOperationsAction.loadOperationActions.insert(action)
        })
    }

    private func prepareRequestData(extole: ExtoleImpl) -> [String: String] {
        var allData: [String: String] = [:]
        data?.forEach({ (key: String, value: String) in
            allData[key] = value
        })
        extole.data.forEach { (key: String, value: String) in
            allData[key] = value
        }
        return allData
    }

    private func removeExecutedActionsFromQueue() {
        let executedOperations = LoadOperationsAction.loadOperationActions.filter { action in
            action.zones == zones
        }
        executedOperations.forEach { action in
            LoadOperationsAction.loadOperationActions.remove(action)
        }
    }

    override init() {
        super.init()
    }

    init(zones: [String], data: [String: String] = [:]) {
        super.init()
        self.zones = zones
        self.data = data
    }

    public func getZones() -> [String]? {
        zones
    }

    public func getData() -> [String: String]? {
        data
    }

    public override func getType() -> ActionType {
        ActionType.LOAD_OPERATIONS
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        zones <- map["zones"]
        data <- map["data"]
        actionType <- map["type"]
    }

    public static func == (lhs: LoadOperationsAction, rhs: LoadOperationsAction) -> Bool {
        lhs.zones == rhs.zones && lhs.data == rhs.data
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(zones)
        hasher.combine(data)
    }

    public var description: String { return "LoadOperationsAction[zones:\(zones), data:\(data)]" }
}
