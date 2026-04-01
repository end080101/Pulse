import Foundation

enum ProcessMonitor {
    static func refresh(completion: @escaping ([ProcessStat]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", "/bin/ps -Ao pcpu,pmem,comm -r | /usr/bin/head -n 11"]
            let pipe = Pipe()
            task.standardOutput = pipe

            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8) else {
                    completion([])
                    return
                }

                let processes = output
                    .components(separatedBy: .newlines)
                    .dropFirst()
                    .compactMap { line -> ProcessStat? in
                        guard !line.isEmpty else { return nil }
                        let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
                        guard parts.count >= 3 else { return nil }

                        let name = String(parts[2]).components(separatedBy: "/").last ?? String(parts[2])
                        return ProcessStat(
                            name: name,
                            cpu: Double(parts[0]) ?? 0.0,
                            memory: Double(parts[1]) ?? 0.0
                        )
                    }

                completion(processes)
            } catch {
                completion([])
            }
        }
    }
}
