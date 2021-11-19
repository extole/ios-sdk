import Foundation
import WebKit

public protocol ExtoleWebView {

    func getWebView() -> WKWebView
    func load(_ zone: String)
}
