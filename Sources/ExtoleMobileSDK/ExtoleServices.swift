import Foundation
import ExtoleConsumerAPI
import SwiftEventBus

public class ExtoleServices {
    private let extole: ExtoleImpl
    private let zoneService: ZoneService
    private let rewardService: RewardService
    private let shareService: ShareService

    init(_ extole: ExtoleImpl) {
        self.extole = extole
        self.zoneService = ZoneService(programDomain: extole.programDomain, logger: extole.getLogger())
        self.rewardService = RewardServiceImpl(extole)
        self.shareService = ShareServiceImpl(extole)
    }

    public func getZoneService() -> ZoneService {
        zoneService
    }

    public func getRewardService() -> RewardService {
        rewardService
    }

    public func getShareService() -> ShareService {
        shareService
    }
}
