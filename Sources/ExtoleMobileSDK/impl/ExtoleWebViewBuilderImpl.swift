import Foundation

public class ExtoleWebViewBuilderImpl: ExtoleWebViewBuilder {

    let programDomain: String
    var headers: [String: String] = [:]
    var data: [String: String] = [:]

    init(_ programDomain: String) {
        self.programDomain = programDomain
    }

    public func addHttpHeader(header: String, value: String) -> ExtoleWebViewBuilder {
        headers[header] = value
        return self
    }

    public func addData(key: String, value: String) -> ExtoleWebViewBuilder {
        data[key] = value
        return self
    }

    public func create() -> ExtoleWebView {
        ExtoleWebViewService(programDomain, data, headers)
    }
}
