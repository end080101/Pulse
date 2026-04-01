import Foundation
import IOKit

enum GPUMonitor {
    static func refresh() -> GPUStats {
        let iterator = UnsafeMutablePointer<io_iterator_t>.allocate(capacity: 1)
        defer { iterator.deallocate() }

        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), iterator) == KERN_SUCCESS else {
            return GPUStats()
        }
        defer { IOObjectRelease(iterator.pointee) }

        var usage = 0.0
        var service = IOIteratorNext(iterator.pointee)
        while service != 0 {
            if let props = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? [String: Any],
               let value = props["Device Utilization %"] as? Int ?? props["GPU Busy %"] as? Int {
                usage = Double(value)
            }

            IOObjectRelease(service)
            service = IOIteratorNext(iterator.pointee)
        }

        return GPUStats(usage: usage)
    }
}
