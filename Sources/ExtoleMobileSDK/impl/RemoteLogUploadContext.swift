import Foundation
import ExtoleConsumerAPI

private let remoteLogUploadContextKey = "com.extole.mobile.sdk.remote_log_upload_context"

enum RemoteLogUploadContext {

    static func withSuppressedRemoteUpload<T>(when shouldSuppress: Bool, _ work: () -> T) -> T {
        guard shouldSuppress else {
            return work()
        }

        let threadDictionary = Thread.current.threadDictionary
        let previousValue = threadDictionary[remoteLogUploadContextKey]
        threadDictionary[remoteLogUploadContextKey] = true

        defer {
            if let previousValue = previousValue {
                threadDictionary[remoteLogUploadContextKey] = previousValue
            } else {
                threadDictionary.removeObject(forKey: remoteLogUploadContextKey)
            }
        }

        return work()
    }

    static var shouldSuppressRemoteUpload: Bool {
        Thread.current.threadDictionary[remoteLogUploadContextKey] as? Bool ?? false
    }
}

enum NetworkConnectivityErrorFilter {

    private static let suppressedUrlErrorCodes: Set<Int> = [
        URLError.Code.notConnectedToInternet.rawValue,
        URLError.Code.networkConnectionLost.rawValue,
        URLError.Code.timedOut.rawValue,
        URLError.Code.internationalRoamingOff.rawValue,
        URLError.Code.callIsActive.rawValue,
        URLError.Code.dataNotAllowed.rawValue
    ]

    static func shouldSuppressRemoteUpload(for error: Error) -> Bool {
        if let errorResponse = error as? ErrorResponse {
            switch errorResponse {
            case let .error(_, _, underlyingError):
                return shouldSuppressRemoteUpload(for: underlyingError)
            }
        }

        if let urlError = error as? URLError,
           suppressedUrlErrorCodes.contains(urlError.code.rawValue) {
            return true
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && suppressedUrlErrorCodes.contains(nsError.code) {
            return true
        }

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error,
           shouldSuppressRemoteUpload(for: underlyingError) {
            return true
        }

        let errorDescription = String(describing: error)
        return suppressedUrlErrorCodes.contains(where: { code in
            errorDescription.contains("NSURLErrorDomain Code=\(code)")
        })
    }
}
