import Foundation

enum StorageMonitor {
    static func refresh() -> StorageStats? {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
              let total = attrs[.systemSize] as? Int64,
              let free = attrs[.systemFreeSize] as? Int64 else {
            return nil
        }

        return StorageStats(
            usedGB: Double(total - free) / 1024 / 1024 / 1024,
            totalGB: Double(total) / 1024 / 1024 / 1024,
            health: 100
        )
    }
}
