import Foundation

public protocol ExtoleBuilder {

    func withAppName(_ appName: String) -> ExtoleBuilder
    func addAppData(_ key: String, _ value: String) -> ExtoleBuilder
    func addData(_ key: String, _ value: String) -> ExtoleBuilder
    func addLabel(_ label: String) -> ExtoleBuilder
    func withSandbox(_ sandbox: String) -> ExtoleBuilder
    func withDebugEnabled(_ debugEnabled: Bool) -> ExtoleBuilder
    func clearData() -> ExtoleBuilder
    func clearLabels() -> ExtoleBuilder
    func withProgramDomain(_ programDomain: String) -> ExtoleBuilder
    func build() -> Extole
}
