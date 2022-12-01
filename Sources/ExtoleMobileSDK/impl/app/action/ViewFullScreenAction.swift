import Foundation
import ObjectMapper
import SwiftUI

public class ViewFullScreenAction: Action, CustomStringConvertible {
    public static var type: ActionType = ActionType.VIEW_FULLSCREEN

    var zoneName: String?
    var actionType: String = type.rawValue
    @State var isActive = true

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        extole.getLogger().debug("ViewFullScreenAction, event=\(event)")
        DispatchQueue.main.async {
            self.isActive = true
            extole.observableUi.bodyContent = AnyView(NavigationLink("",
                destination: UIExtoleWebView(extole.webView(), self.zoneName ?? ""),
                isActive: self.$isActive))
        }
    }

    init(zoneName: String) {
        super.init()
        self.zoneName = zoneName
    }

    override init() {
        super.init()
    }

    public func getZoneName() -> String? {
        zoneName
    }

    public override func getType() -> ActionType {
        ActionType.VIEW_FULLSCREEN
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        zoneName <- map["zone_name"]
        actionType <- map["type"]
    }

    public var description: String { return "ViewFullScreenAction[zoneName:\(zoneName)]" }
}
