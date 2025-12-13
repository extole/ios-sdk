import Foundation
import ObjectMapper
import SwiftUI

public class ViewFullScreenAction: Action, CustomStringConvertible {
    public static var type: ActionType = ActionType.VIEW_FULLSCREEN

    var zoneName: String?
    var actionType: String = type.rawValue

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        extole.getLogger().debug("ViewFullScreenAction, event=\(event)")
        DispatchQueue.main.async {
            var eventData: [String:String] = [:]
            event.eventData.forEach { item in
                eventData[item.key] = item.value as? String
            }
            let uniqueId = UUID().uuidString
            extole.observableUi.bodyContent = AnyView(NavigationLinkWrapper(
                destination: UIExtoleWebView(extole.webView(data: eventData), self.zoneName ?? ""),
                id: uniqueId
            ))
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

    public var description: String { return "ViewFullScreenAction[zoneName:\(String(describing: zoneName))]" }
}

private struct NavigationLinkWrapper: View {
    let destination: UIExtoleWebView
    let id: String
    @State private var isActive = false
    
    var body: some View {
        NavigationLink("", destination: destination, isActive: $isActive)
            .onAppear {
                isActive = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isActive = true
                }
            }
            .id(id)
    }
}
