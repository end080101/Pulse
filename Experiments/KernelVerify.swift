import Foundation
import Darwin

// 1. 采用与 MiniStat 相同的内核级 sysctl 统计逻辑
func getKernelBytes() -> (UInt64, UInt64) {
    var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
    var len: Int = 0
    if sysctl(&mib, 6, nil, &len, nil, 0) < 0 { return (0, 0) }
    var buffer = [Int8](repeating: 0, count: len)
    if sysctl(&mib, 6, &buffer, &len, nil, 0) < 0 { return (0, 0) }
    var totalIn: UInt64 = 0
    var totalOut: UInt64 = 0
    var offset = 0
    while offset < len {
        let ptr = buffer.withUnsafeBufferPointer { $0.baseAddress!.advanced(by: offset) }
        let hdr = ptr.withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
        if hdr.ifm_type == RTM_IFINFO2 {
            let hdr2 = ptr.withMemoryRebound(to: if_msghdr2.self, capacity: 1) { $0.pointee }
            // 过滤 lo0 (index 1)
            if hdr2.ifm_index > 1 {
                totalIn += hdr2.ifm_data.ifi_ibytes
                totalOut += hdr2.ifm_data.ifi_obytes
            }
        }
        offset += Int(hdr.ifm_msglen)
    }
    return (totalIn, totalOut)
}

print("Running Kernel Network Verification (5s)...")
let (in1, out1) = getKernelBytes()
Thread.sleep(forTimeInterval: 5.0)
let (in2, out2) = getKernelBytes()

let diffIn = Double(in2 - in1) / 5.0 / 1024.0
let diffOut = Double(out2 - out1) / 5.0 / 1024.0

print(String(format: "MiniStat Kernel Logic: Down %.2f KB/s, Up %.2f KB/s", diffIn, diffOut))
