import Foundation
import ExtoleConsumerAPI
import CryptoKit

func httpCallFor<T>(_ requestBuilder: RequestBuilder<T>,
                    _ programDomain: String,
                    _ customHeaders: [String: String]) -> RequestBuilder<T> {
    requestBuilder.withProgramDomain(programDomain)
    requestBuilder.addHeaders(customHeaders)
    return requestBuilder
}

func sha256(_ value: String) -> String {
    return SHA256.hash(data: value.data(using: .utf8) ?? Data("".utf8))
        .map { String(format: "%02X", $0) }.joined()
}
