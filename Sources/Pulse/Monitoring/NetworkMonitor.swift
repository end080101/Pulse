import Foundation
import Darwin
import CoreWLAN

final class NetworkMonitor {
    private var prevInBytes: UInt64 = 0
    private var prevOutBytes: UInt64 = 0
    private var primaryInterfaceName: String?

    func refreshUsage(current: NetworkStats, interval: TimeInterval) -> NetworkStats? {
        let previousInterface = primaryInterfaceName
        refreshPrimaryInterfaceNameIfNeeded(force: true)

        if previousInterface != primaryInterfaceName {
            prevInBytes = 0
            prevOutBytes = 0
        }

        let counters = networkCounters()
        guard let counters else { return nil }

        var next = current
        if prevInBytes != 0 && interval > 0 {
            let down = Double(counters.inBytes - prevInBytes) / interval / 1024
            let up = Double(counters.outBytes - prevOutBytes) / interval / 1024
            next.downKBps = down
            next.upKBps = up
            next.downHistory.append(down)
            next.upHistory.append(up)
            if next.downHistory.count > 20 {
                next.downHistory.removeFirst()
            }
            if next.upHistory.count > 20 {
                next.upHistory.removeFirst()
            }
            let (ipv4, ipv6) = localIPAddresses()
            next.localIPv4 = ipv4
            next.localIPv6 = ipv6
        }

        prevInBytes = counters.inBytes
        prevOutBytes = counters.outBytes
        return next
    }

    func refreshWiFiName(current: NetworkStats) -> NetworkStats {
        var next = current

        refreshPrimaryInterfaceNameIfNeeded(force: true)

        if let interfaceName = primaryInterfaceName,
           let wifiInterface = CWWiFiClient.shared().interface(withName: interfaceName),
           let ssid = wifiInterface.ssid(),
           !ssid.isEmpty {
            next.wifiSSID = ssid
            return next
        }

        if let ssid = CWWiFiClient.shared().interface()?.ssid(), !ssid.isEmpty {
            next.wifiSSID = ssid
            return next
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-getairportnetwork", primaryInterfaceName ?? "en1"]
        let pipe = Pipe()
        task.standardOutput = pipe

        if (try? task.run()) != nil {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               output.contains("Current Wi-Fi Network: ") {
                next.wifiSSID = output
                    .replacingOccurrences(of: "Current Wi-Fi Network: ", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return next
    }

    func refreshPing(completion: @escaping (Double) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/sbin/ping")
            task.arguments = ["-c", "1", "-t", "1", "1.1.1.1"]
            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8),
                      let range = output.range(of: "time=") else {
                    completion(-1)
                    return
                }

                let value = output[range.upperBound...]
                    .components(separatedBy: " ")
                    .first?
                    .replacingOccurrences(of: "ms", with: "") ?? "0"
                completion(Double(value) ?? -1)
            } catch {
                completion(-1)
            }
        }
    }

    func fetchPublicIP(completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.ipify.org") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let ip = String(data: data, encoding: .utf8), !ip.isEmpty else { return }
            completion(ip)
        }.resume()
    }

    private func networkCounters() -> (inBytes: UInt64, outBytes: UInt64)? {
        guard let targetInterface = primaryInterfaceName ?? resolvePrimaryInterfaceName() else {
            return nil
        }

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var pointer = ifaddr
        while let current = pointer {
            let interface = current.pointee
            let name = String(cString: interface.ifa_name)

            if name == targetInterface,
               let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                return (UInt64(data.pointee.ifi_ibytes), UInt64(data.pointee.ifi_obytes))
            }

            pointer = interface.ifa_next
        }

        return nil
    }

    private func localIPAddresses() -> (String, String) {
        var ipv4 = "127.0.0.1"
        var ipv6 = ""
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        let targetInterface = primaryInterfaceName ?? resolvePrimaryInterfaceName()

        guard getifaddrs(&ifaddr) == 0 else {
            return (ipv4, ipv6)
        }
        defer { freeifaddrs(ifaddr) }

        var pointer = ifaddr
        while pointer != nil {
            let interface = pointer!.pointee
            guard let address = interface.ifa_addr else {
                pointer = interface.ifa_next
                continue
            }

            let family = address.pointee.sa_family
            let name = String(cString: interface.ifa_name)
            if name == targetInterface || (targetInterface == nil && (name == "en1" || (ipv4 == "127.0.0.1" && name == "en0"))) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                let value = String(cString: host)

                if family == UInt8(AF_INET) {
                    ipv4 = value
                } else if family == UInt8(AF_INET6) {
                    let normalized = value.components(separatedBy: "%").first ?? ""
                    if !normalized.hasPrefix("fe80") && !normalized.isEmpty {
                        ipv6 = normalized
                    } else if ipv6.isEmpty {
                        ipv6 = normalized
                    }
                }
            }

            pointer = interface.ifa_next
        }

        return (ipv4, ipv6)
    }

    private func refreshPrimaryInterfaceNameIfNeeded(force: Bool = false) {
        if force || primaryInterfaceName == nil {
            primaryInterfaceName = resolvePrimaryInterfaceName()
        }
    }

    private func resolvePrimaryInterfaceName() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/sbin/route")
        task.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        task.standardOutput = pipe

        guard (try? task.run()) != nil else { return primaryInterfaceName }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return primaryInterfaceName }

        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("interface:") {
                let name = trimmed.replacingOccurrences(of: "interface:", with: "").trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    return name
                }
            }
        }

        return primaryInterfaceName
    }
}
