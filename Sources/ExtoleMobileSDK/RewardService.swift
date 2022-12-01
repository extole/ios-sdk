import Foundation
import ExtoleConsumerAPI
import SwiftEventBus

public protocol RewardService {

    func pollReward(pollingId: String, timeoutSeconds: Int, retries: Int, completion: @escaping (PollingRewardResponse?, Error?) -> Void)
}

extension RewardService {
    public func pollReward(pollingId: String, timeoutSeconds: Int = 5, retries: Int = 5, completion: @escaping (PollingRewardResponse?, Error?) -> Void) {
        return pollReward(pollingId: pollingId, timeoutSeconds: timeoutSeconds, retries: retries, completion: completion)
    }
}
