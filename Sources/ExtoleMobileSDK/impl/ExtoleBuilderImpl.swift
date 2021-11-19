import Foundation

class ExtoleBuilderImpl: ExtoleBuilder {

    var programDomain: String = ""
    var appName: String = "Extole Mobile SDK"
    var appData: [String: String] = [:]
    var data: [String: String] = [:]
    var labels: [String] = []
    var sandbox: String = "prod-prod"
    var debugEnabled: Bool = false

    init() {
    }

    init(programDomain: String, appName: String, appData: [String: String], data: [String: String],
         labels: [String], sandbox: String, debugEnabled: Bool) {
        self.programDomain = programDomain
        self.appName = appName
        self.appData = appData
        self.data = data
        self.labels = labels
        self.sandbox = sandbox
        self.debugEnabled = debugEnabled
    }

    func withAppName(_ appName: String) -> ExtoleBuilder {
        self.appName = appName
        return self
    }

    func addAppData(_ key: String, _ value: String) -> ExtoleBuilder {
        self.appData[key] = value
        return self
    }

    func addData(_ key: String, _ value: String) -> ExtoleBuilder {
        self.data[key] = value
        return self
    }

    func addLabel(_ label: String) -> ExtoleBuilder {
        self.labels.append(label)
        return self
    }

    func withSandbox(_ sandbox: String) -> ExtoleBuilder {
        self.sandbox = sandbox
        return self
    }

    // implement support in stub library ENG-15946
    func withDebugEnabled(_ debugEnabled: Bool) -> ExtoleBuilder {
        self.debugEnabled = debugEnabled
        return self
    }

    func clearData() -> ExtoleBuilder {
        self.data = [:]
        return self
    }

    func clearLabels() -> ExtoleBuilder {
        self.labels = []
        return self
    }

    func withProgramDomain(_ programDomain: String) -> ExtoleBuilder {
        self.programDomain = programDomain
        return self
    }

    func build() -> Extole {
        ExtoleService(programDomain: programDomain, applicationName: appName, applicationData: appData,
                data: data, labels: labels, sandbox: sandbox, debugEnabled: debugEnabled)
    }
}
