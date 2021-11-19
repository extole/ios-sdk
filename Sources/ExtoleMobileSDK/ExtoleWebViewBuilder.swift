import Foundation

public protocol ExtoleWebViewBuilder {
    func withHttpHeaders(headers: [String: String]) -> ExtoleWebViewBuilder
    func withData(data: [String: String]) -> ExtoleWebViewBuilder
    func create() -> ExtoleWebView
}
