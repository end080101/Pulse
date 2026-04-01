import Foundation
import Darwin

final class CPUMonitor {
    private var numCPUs: mach_msg_type_number_t = 0
    private var prevCPUInfo: processor_info_array_t?
    private var numPrevCPUInfo: mach_msg_type_number_t = 0

    deinit {
        guard let prevCPUInfo else { return }
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCPUInfo), vm_size_t(numPrevCPUInfo))
    }

    func refresh(history: [Double]) -> CPUStats? {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo else { return nil }
        guard let prevCPUInfo else {
            self.prevCPUInfo = cpuInfo
            self.numPrevCPUInfo = numCPUInfo
            return nil
        }

        var totalUsage = 0.0
        for index in 0 ..< Int(numCPUs) {
            let offset = index * Int(CPU_STATE_MAX)
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)] - prevCPUInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)] - prevCPUInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)] - prevCPUInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)] - prevCPUInfo[offset + Int(CPU_STATE_NICE)])
            let total = user + system + idle + nice
            if total > 0 {
                totalUsage += (user + system + nice) / total
            }
        }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCPUInfo), vm_size_t(numPrevCPUInfo))
        self.prevCPUInfo = cpuInfo
        self.numPrevCPUInfo = numCPUInfo

        let usage = (totalUsage / Double(numCPUs)) * 100.0
        var nextHistory = history
        nextHistory.append(usage)
        if nextHistory.count > 20 {
            nextHistory.removeFirst()
        }

        return CPUStats(usage: usage, history: nextHistory)
    }
}
