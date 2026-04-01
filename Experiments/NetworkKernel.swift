import Foundation
import Darwin

// 采用内核级 sysctl 统计方式，完全对齐 Activity Monitor
func getSystemNetworkBytes() -> (UInt64, UInt64) {
    var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
    var len: Int = 0
    
    // 1. 获取需要的缓冲区长度
    if sysctl(&mib, 6, nil, &len, nil, 0) < 0 { return (0, 0) }
    
    // 2. 读取数据到缓冲区
    var buffer = [Int8](repeating: 0, count: len)
    if sysctl(&mib, 6, &buffer, &len, nil, 0) < 0 { return (0, 0) }
    
    var totalIn: UInt64 = 0
    var totalOut: UInt64 = 0
    
    var offset = 0
    while offset < len {
        let ptr = buffer.withUnsafeBufferPointer { $0.baseAddress!.advanced(by: offset) }
        let hdr = ptr.withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
        
        // 我们只关注 RTM_IFINFO2 类型的消息，它包含了 64 位统计数据
        if hdr.ifm_type == RTM_IFINFO2 {
            let hdr2 = ptr.withMemoryRebound(to: if_msghdr2.self, capacity: 1) { $0.pointee }
            
            // 关键：过滤掉 Loopback 接口 (index 1 通常是 lo0)
            // 并且只统计物理接口及其关联层，避免重复计算
            if hdr2.ifm_index > 1 {
                // Activity Monitor 的逻辑是加总所有非回环接口的 64 位计数器
                totalIn += hdr2.ifm_data.ifi_ibytes
                totalOut += hdr2.ifm_data.ifi_obytes
            }
        }
        offset += Int(hdr.ifm_msglen)
    }
    
    return (totalIn, totalOut)
}

// 接下来我将这段逻辑合并到 SystemMonitor.swift
