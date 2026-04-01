import Foundation
import IOKit.ps

enum BatteryMonitor {
    static func refresh() -> BatteryStats {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        guard !sources.isEmpty else {
            return BatteryStats(hasBattery: false)
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let level = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
            let cycles = description["Cycle Count"] as? Int ?? 0
            let designCapacity = max(description[kIOPSDesignCapacityKey] as? Int ?? 100, 1)
            let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
            let timeToEmpty = description[kIOPSTimeToEmptyKey] as? Int ?? -1

            var timeRemaining = "--:--"
            if timeToEmpty > 0 {
                timeRemaining = String(format: "%dh %02dm", timeToEmpty / 60, timeToEmpty % 60)
            } else if isCharging {
                timeRemaining = "Charging"
            }

            return BatteryStats(
                level: level,
                isCharging: isCharging,
                health: (maxCapacity * 100) / designCapacity,
                cycles: cycles,
                timeRemaining: timeRemaining,
                hasBattery: true
            )
        }

        return BatteryStats(hasBattery: false)
    }
}
