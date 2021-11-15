import Foundation

public protocol ExtoleWebViewBuilder {
    func addHttpHeader(header: String, value: String) -> ExtoleWebViewBuilder
    func addData(key: String, value: String) -> ExtoleWebViewBuilder
    func create() -> ExtoleWebView
}
