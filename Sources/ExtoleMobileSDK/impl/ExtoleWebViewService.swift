import SwiftUI
@preconcurrency import WebKit
import JavaScriptCore

public struct UIExtoleWebView: View {
    let zoneName: String
    let extoleWebView: ExtoleWebView
    private let uniqueId: String
    @State private var isLoading = true

    public init(_ extoleWebView: ExtoleWebView, _ zoneName: String) {
        self.extoleWebView = extoleWebView
        self.zoneName = zoneName
        self.uniqueId = UUID().uuidString
    }

    public init(_ programDomain: String, _ zoneName: String, _ queryParameters: inout [String: String],
                _ headers: inout [String: String]) {
        self.extoleWebView = ExtoleWebViewService(programDomain, queryParameters, headers)
        self.zoneName = zoneName
        self.uniqueId = UUID().uuidString
    }
    
    public var body: some View {
        ZStack {
            WebViewRepresentable(
                extoleWebView: extoleWebView,
                zoneName: zoneName,
                uniqueId: uniqueId,
                isLoading: $isLoading
            )
            
            if isLoading {
                if #available(iOS 14.0, *) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.8))
                }
            }
        }
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let extoleWebView: ExtoleWebView
    let zoneName: String
    let uniqueId: String
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = extoleWebView.getWebView()
        
        if let webViewService = extoleWebView as? ExtoleWebViewService {
            webViewService.setLoadingStateChanged { loading in
                DispatchQueue.main.async {
                    isLoading = loading
                }
            }
        }
        
        DispatchQueue.main.async {
            extoleWebView.load(zoneName)
        }
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
    }
}

class ExtoleWebViewService: NSObject, ExtoleWebView, WKNavigationDelegate {
    let SUPPORTED_PROTOCOL_HANDLERS = ["tel", "sms", "facetime", "mailto"]

    let programDomain: String
    let webView: WKWebView
    var queryParameters: [String: String]
    var headers: [String: String]
    private var loadingStateChanged: ((Bool) -> Void)?

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
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        super.init()
        webView.navigationDelegate = self
    }

    func getWebView() -> WKWebView {
        webView
    }
    
    func setLoadingStateChanged(_ callback: @escaping (Bool) -> Void) {
        loadingStateChanged = callback
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
        loadingStateChanged?(true)
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
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingStateChanged?(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingStateChanged?(false)
        
        let accessToken = headers["Authorization"]?.replacingOccurrences(of: "Bearer ", with: "")
        if accessToken != nil {
            NSLog("WebView setting accessTokenTo: \(accessToken ?? "")")
            let js = """
            (function() {
                function waitForExtole() {
                    if (window.extole && extole.tokenStore && typeof extole.tokenStore.set === 'function') {
                        extole.tokenStore.set('\(accessToken ?? "")');
                    } else {
                        setTimeout(waitForExtole, 50);
                    }
                }
                waitForExtole();
            })();
            """
            webView.evaluateJavaScript(js)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingStateChanged?(false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingStateChanged?(false)
    }
}
