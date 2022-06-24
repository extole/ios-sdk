import Foundation

public protocol Campaign: Extole {

    func getProgram() -> String
    func getId() -> Id<Campaign>
}

extension Campaign {

    public func webView(headers: [String: String] = [:], data: [String: String] = [:]) -> ExtoleWebView {
        return webView(headers: headers, data: data)
    }
}
