import Foundation

public class Me {
    public let email: String?
    public let firstName: String?
    public let lastName: String?
    public let partnerUserId: String?
    public let profilePictureUrl: String?

    init(email: String? = nil, firstName: String? = nil, lastName: String? = nil, partnerUserId: String? = nil,
         profilePictureUrl: String? = nil) {
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.partnerUserId = partnerUserId
        self.profilePictureUrl = profilePictureUrl
    }
}
