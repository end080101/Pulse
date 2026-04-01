import Foundation
import Darwin

enum AppMetadata {
    static let displayName = "Pulse"

    static var versionString: String {
        if let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !value.isEmpty {
            return value
        }
        return "1.0.0"
    }
}

enum MachineInfo {
    static func modelName() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)

        let modelID = String(cString: model)
        if modelID.contains("Mac15") || modelID.contains("Mac16") {
            return "Mac mini M4"
        }
        return modelID
    }
}
