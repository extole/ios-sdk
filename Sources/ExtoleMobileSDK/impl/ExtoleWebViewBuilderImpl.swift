import Foundation

public class ExtoleWebViewBuilderImpl: ExtoleWebViewBuilder {

    let programDomain: String
    var headers: [String: String] = [:]
    var data: [String: String] = [:]

    init(_ programDomain: String) {
        self.programDomain = programDomain
    }

    public func withHttpHeaders(headers: [String: String]) -> ExtoleWebViewBuilder {
        self.headers = headers
        return self
    }

    public func withData(data: [String: String]) -> ExtoleWebViewBuilder {
        self.data = data
        return self
    }

    public func create() -> ExtoleWebView {
        return ExtoleWebViewService(programDomain, data, headers)
    }
}
