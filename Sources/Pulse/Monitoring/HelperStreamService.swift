import Foundation

struct HelperPayload {
    var temperature: Double?
    var packageMilliwatts: Double?
    var wifiSSID: String?
}

final class HelperStreamService {
    var onPayload: ((HelperPayload) -> Void)?

    private let helperSystemPath = "/Library/PrivilegedHelperTools/com.user.PulseHelperV1"
    private var buffer = ""
    private var task: Process?

    func start() {
        let candidates = [helperSystemPath, bundledHelperPath()].compactMap { $0 }
        guard let executablePath = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            return
        }

        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: executablePath)
        task.standardOutput = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self else { return }
            let data = handle.availableData
            guard !data.isEmpty, let string = String(data: data, encoding: .utf8) else { return }
            self.consume(string)
        }

        do {
            try task.run()
            self.task = task
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
        }
    }

    func stop() {
        task?.terminate()
        task = nil
    }

    private func bundledHelperPath() -> String? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        return resourcePath + "/ThermalHelper"
    }

    private func consume(_ string: String) {
        buffer += string
        while let index = buffer.firstIndex(of: "\n") {
            let line = String(buffer.prefix(upTo: index))
            buffer.removeSubrange(...index)
            if let payload = parse(line) {
                onPayload?(payload)
            }
        }
    }

    private func parse(_ line: String) -> HelperPayload? {
        guard line.contains("DATA|") else { return nil }

        var payload = HelperPayload()
        for part in line.split(separator: "|") {
            if part.hasPrefix("TEMP:"), let value = Double(part.dropFirst(5)) {
                payload.temperature = value
            } else if part.hasPrefix("PACKAGE_MW:"), let value = Double(part.dropFirst(11)) {
                payload.packageMilliwatts = value
            } else if part.hasPrefix("SOC_MW:"), let value = Double(part.dropFirst(7)) {
                payload.packageMilliwatts = value
            } else if part.hasPrefix("SSID:") {
                payload.wifiSSID = String(part.dropFirst(5))
            }
        }

        return payload
    }
}
