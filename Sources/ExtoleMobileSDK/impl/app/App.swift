import Foundation
import SwiftEventBus

class App {
    var extole: ExtoleImpl

    init(extole: ExtoleImpl) {
        self.extole = extole
        SwiftEventBus.onMainThread(extole, name: "event") { result in
            let event: AppEvent = result?.object as! AppEvent
            AppEngine(extole.operations).execute(event: event, extole: extole)
        }
    }
}
