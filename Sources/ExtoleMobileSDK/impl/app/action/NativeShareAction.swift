import Foundation
import ObjectMapper
import UIKit

public class NativeShareAction: Action, CustomStringConvertible {
    public static var type: ActionType = ActionType.NATIVE_SHARE

    var zone: String?
    var message: String?
    var image: String?
    var actionType: String = type.rawValue

    public override func execute(event: AppEvent, extole: ExtoleImpl) {
        extole.getLogger().debug("NativeShareAction, event=\(event)")
        if zone != nil {
            extole.fetchZone(zone ?? "", [:]) { [self] (zone: Zone?, _: Campaign?, _: Error?) in
                shareButton(message: zone?.get("message") as! String? ?? "", image: self.image)
            }
        } else {
            shareButton(message: self.message, image: self.image)
        }

    }

    func shareButton(message: String?, image: String?) {
            // let url = URL(string: url)
            let imageUrl = URL(string: image ?? "")
            let activityController = UIActivityViewController(activityItems: [imageUrl!, message ?? ""], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
    }

    init(zone: String?, message: String?, image: String?) {
        super.init()
        self.zone = zone
        self.message = message
        self.image = image
    }

    override init() {
        super.init()
    }

    public override func getType() -> ActionType {
        ActionType.NATIVE_SHARE
    }

    public required init?(map: Map) {
        super.init()
    }

    public override func mapping(map: Map) {
        zone <- map["zone"]
        message <- map["message"]
        image <- map["image"]
        actionType <- map["type"]
    }

    public var description: String { return "NativeShareAction[zone:\(zone ?? ""), message:\(message ?? ""), image:\(image ?? "")]" }

}
