import Foundation
import ExtoleConsumerAPI
import SwiftEventBus

public class ExtoleServices {
    private let extole: ExtoleImpl
    private let zoneFetcher: ZoneFetcher
    private let rewardService: RewardService
    private let shareService: ShareService

    init(_ extole: ExtoleImpl) {
        self.extole = extole
        self.zoneFetcher = ZoneFetcher(programDomain: extole.programDomain, logger: extole.getLogger(), extole: extole)
        self.rewardService = RewardServiceImpl(extole)
        self.shareService = ShareServiceImpl(extole)
    }

    public func getZoneFetcher() -> ZoneFetcher {
        zoneFetcher
    }

    public func getRewardService() -> RewardService {
        rewardService
    }

    public func getShareService() -> ShareService {
        shareService
    }
}
