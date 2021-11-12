import Foundation
import ExtoleConsumerAPI

func httpCallFor<T>(_ requestBuilder: RequestBuilder<T>,
                    _ programDomain: String,
                    _ customHeaders: [String: String]) -> RequestBuilder<T> {
    requestBuilder.withProgramDomain(programDomain)
    requestBuilder.addHeaders(customHeaders)
    return requestBuilder
}
