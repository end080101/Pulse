import Foundation

enum MemoryMonitor {
    static func refresh() -> MemoryStats? {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let usedPages = UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return MemoryStats(
            usedGB: Double(usedPages) * Double(pageSize) / 1024 / 1024 / 1024,
            totalGB: Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024 / 1024
        )
    }
}
