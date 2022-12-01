import Foundation

class AppEngine {
    private let operations: [ExtoleOperation]

    static let LOAD_DONE_EVENT = "load_done"
    static let LOAD_EVENTS = ["on_load", "app_initialized"]
    static var appInitialized: Bool = false
    static var eventsQueue: [AppEvent] = []

    init(_ operations: [ExtoleOperation]) {
        self.operations = operations
    }

    func execute(event: AppEvent, extole: ExtoleImpl) {
        AppEngine.eventsQueue.append(event)
        if event.eventName == AppEngine.LOAD_DONE_EVENT {
            AppEngine.appInitialized = true
            extole.getLogger().debug("App initialized, queued events \(AppEngine.eventsQueue)")
        }
        if AppEngine.LOAD_EVENTS.contains(event.eventName) {
            let queuedEvent = AppEngine.eventsQueue.removeLast()
            executeOperations(event: queuedEvent, extole: extole)
        }

        while AppEngine.appInitialized && !AppEngine.eventsQueue.isEmpty {
            let queuedEvent = AppEngine.eventsQueue.removeLast()
            extole.getLogger().debug("Handling event: \(queuedEvent)")
            executeOperations(event: queuedEvent, extole: extole)
        }

    }

    private func executeOperations(event: AppEvent, extole: ExtoleImpl) {
        operations.forEach { operation in
            operation.executeActions(event: event, extole: extole)
        }
    }

    private func eventCanBeProcessed(event: AppEvent) -> Bool {
        (AppEngine.LOAD_EVENTS.contains(event.eventName) || AppEngine.appInitialized) && !AppEngine.eventsQueue.isEmpty
    }
}
