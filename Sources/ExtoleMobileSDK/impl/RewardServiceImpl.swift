import Foundation
import Logging
import ExtoleConsumerAPI
import SwiftUI

class RewardServiceImpl: RewardService {

    let extole: ExtoleImpl

    init(_ extole: ExtoleImpl) {
        self.extole = extole
    }

    public func pollReward(pollingId: String, timeoutSeconds: Int = 5, retries: Int = 5, completion: @escaping (PollingRewardResponse?, Error?) -> Void) {
        let request = MeRewardEndpoints.getRewardStatusWithRequestBuilder(pollingId: pollingId)

        var rewardResponseWasReceived = false
        let dispatchGroup = DispatchGroup()
        for _ in 0...retries {
            dispatchGroup.enter()
            httpCallFor(request, extole.programDomain + "/api", extole.customHeaders)
              .execute { (pollingRewardResponse: Response<PollingRewardResponse>?, error: Error?) in
                  dispatchGroup.leave()
                  if pollingRewardResponse?.body?.status != PollingRewardResponse.Status.pending || error != nil {
                      rewardResponseWasReceived = true
                      return completion(pollingRewardResponse?.body, error)
                  }
              }
            sleep(UInt32(timeoutSeconds * 1_000_000))
            dispatchGroup.wait(timeout: .now() + 5)
        }
        if !rewardResponseWasReceived {
            extole.getLogger().debug("reward response was not received")
            completion(nil, nil)
        }
    }
}
