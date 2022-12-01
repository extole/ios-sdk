import Foundation

import ExtoleConsumerAPI

public class Zone {
    let zoneName: String
    let campaignId: Id<Campaign>
    let content: [String: Entry?]?

    init(zoneName: String, campaignId: Id<Campaign>, content: [String: Entry?]?) {
        self.zoneName = zoneName
        self.campaignId = campaignId
        self.content = content
    }

    public func getName() -> String {
        zoneName
    }

    public func get(_ dottedPath: String) -> Any? {
        if dottedPath.contains(".") {
            return getFlatten(dottedPath)
        }
        return content?[dottedPath]??.jsonValue as Any?
    }

    private func getFlatten(_ dottedPath: String) -> Any? {
        var initialReference: [String: Entry?]? = content
        let path = dottedPath.split(separator: ".")
        for index in 0...path.count - 2 {
            let currentPath = String(path[index])
            let jsonValue = initialReference?[currentPath]??.jsonValue
            initialReference = jsonValue as! [String: Entry?]?
        }
        if initialReference != nil {
            return initialReference?[String(path[path.count - 1])]??.jsonValue as Any?
        }
        return nil
    }
}
