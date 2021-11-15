import SwiftUI
import WebKit
import JavaScriptCore
import UIKit

public struct UIExtoleWebView: UIViewRepresentable {
    let zoneName: String
    let extoleWebView: ExtoleWebViewService
    let header: [String: String] = [:]
    let queryParameters: [String: String] = [:]

    public init(_ programDomain: String, _ zoneName: String, _ queryParameters: [String: String] = [:],
                _ headers: [String: String] = [:]) {
        self.extoleWebView = ExtoleWebViewService(programDomain, queryParameters, headers)
        self.zoneName = zoneName
    }

    public func makeUIView(context: Context) -> WKWebView {
        extoleWebView.load(zoneName)
        return extoleWebView.webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        extoleWebView.load(zoneName)
    }
}

class ExtoleWebViewService: NSObject, ExtoleWebView {
    let SUPPORTED_PROTOCOL_HANDLERS = ["tel", "sms", "facetime", "mailto"]

    let programDomain: String
    let webView: WKWebView
    let queryParameters: [String: String]
    let headers: [String: String]

    init(_ programDomain: String, _ queryParameters: [String: String] = [:], _ headers: [String: String] = [:]) {
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

    func load(_ zone: String) {
        var urlComps = URLComponents(string: "\(programDomain)/zone/\(zone)")!
        urlComps.queryItems = queryParameters.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        var request = URLRequest(url: urlComps.url!)
        headers.forEach { key, value in
            request.addValue(key, forHTTPHeaderField: value)
        }
        webView.load(request)
    }
}

extension ExtoleWebViewService: WKNavigationDelegate {

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
}
