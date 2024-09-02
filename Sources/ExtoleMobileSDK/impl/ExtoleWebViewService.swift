import SwiftUI
import WebKit
import JavaScriptCore

public struct UIExtoleWebView: UIViewRepresentable {
    let zoneName: String
    let extoleWebView: ExtoleWebView

    public init(_ extoleWebView: ExtoleWebView, _ zoneName: String) {
        self.extoleWebView = extoleWebView
        self.zoneName = zoneName
    }

    public init(_ programDomain: String, _ zoneName: String, _ queryParameters: inout [String: String],
                _ headers: inout [String: String]) {
        self.extoleWebView = ExtoleWebViewService(programDomain, queryParameters, headers)
        self.zoneName = zoneName
    }

    public func makeUIView(context: Context) -> WKWebView {
        extoleWebView.getWebView()
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        extoleWebView.load(zoneName)
    }
}

class ExtoleWebViewService: NSObject, ExtoleWebView, WKNavigationDelegate {
    let SUPPORTED_PROTOCOL_HANDLERS = ["tel", "sms", "facetime", "mailto"]

    let programDomain: String
    let webView: WKWebView
    var queryParameters: [String: String]
    var headers: [String: String]

    init(_ programDomain: String, _ queryParameters: [String: String], _ headers: [String: String]) {
        self.programDomain = programDomain
        self.queryParameters = queryParameters
        self.headers = headers

        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true

        super.init()
        webView.navigationDelegate = self
    }

    func getWebView() -> WKWebView {
        webView
    }
    
    func load(_ zone: String) {
        var urlComps = URLComponents(string: "\(programDomain)/zone/\(zone)")!
        urlComps.queryItems = queryParameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        var request = URLRequest(url: urlComps.url!)
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        webView.load(request)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if SUPPORTED_PROTOCOL_HANDLERS.contains(url.scheme ?? "") && UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let accessToken = headers["Authorization"]?.replacingOccurrences(of: "Bearer ", with: "")
        if accessToken != nil {
            NSLog("WebView setting accessTokenTo: \(accessToken ?? "")")
            webView.evaluateJavaScript("extole.tokenStore.set('\(accessToken ?? "")')")
        }
    }
}
