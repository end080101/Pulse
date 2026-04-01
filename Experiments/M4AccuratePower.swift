import Foundation
import Darwin

// 核心 IOReport 桥接
typealias IOReportCopyChannelsInGroup = @convention(c) (CFString?, CFString?, UInt64, UInt64, UInt64) -> Unmanaged<CFDictionary>?
typealias IOReportCreateSamples = @convention(c) (CFDictionary, CFDictionary?, UnsafeRawPointer?) -> Unmanaged<CFDictionary>?
typealias IOReportIterate = @convention(c) (CFDictionary, @convention(block) (UnsafeRawPointer) -> Int32) -> Int32
typealias IOReportSimpleGetRawValue = @convention(c) (UnsafeRawPointer, Int32) -> Int64
typealias IOReportChannelGetChannelName = @convention(c) (UnsafeRawPointer) -> Unmanaged<CFString>?

func getAccurateM4Power() {
    guard let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_NOW) else { return }
    
    let copyCh = unsafeBitCast(dlsym(handle, "IOReportCopyChannelsInGroup"), to: IOReportCopyChannelsInGroup.self)
    let createSamples = unsafeBitCast(dlsym(handle, "IOReportCreateSamples"), to: IOReportCreateSamples.self)
    let iterate = unsafeBitCast(dlsym(handle, "IOReportIterate"), to: IOReportIterate.self)
    let getVal = unsafeBitCast(dlsym(handle, "IOReportSimpleGetRawValue"), to: IOReportSimpleGetRawValue.self)
    let getName = unsafeBitCast(dlsym(handle, "IOReportChannelGetChannelName"), to: IOReportChannelGetChannelName.self)
    
    // 寻找 "Energy" 组，这里包含 PPackage, PDRAM, PCPU 等真实物理数值
    guard let channels = copyCh("Energy" as CFString, nil, 0, 0, 0)?.takeRetainedValue() else {
        print("Failed to access Energy group")
        return
    }
    
    print("M4 Real-time Energy Monitoring (Wait 1s)...")
    
    // 采样 1
    guard let s1 = createSamples(channels, nil, nil)?.takeRetainedValue() else { return }
    Thread.sleep(forTimeInterval: 1.0)
    // 采样 2
    guard let s2 = createSamples(channels, nil, nil)?.takeRetainedValue() else { return }
    
    var powerMap: [String: Double] = [:]
    
    // 我们需要对比两次采样的差值来计算功耗 (W = Joules / Second)
    _ = iterate(s2) { ptr2 in
        let name = getName(ptr2)?.takeRetainedValue() as String? ?? ""
        let val2 = getVal(ptr2, 0)
        
        _ = iterate(s1) { ptr1 in
            let name1 = getName(ptr1)?.takeRetainedValue() as String? ?? ""
            if name == name1 {
                let val1 = getVal(ptr1, 0)
                let diff = Double(val2 - val1)
                // 差值是毫焦耳(mJ)或微焦耳，通常需要除以 1e9 得到焦耳，由于间隔是 1s，数值即为瓦特
                // IOReport 的能量单位通常是积分值，需要特定系数。
                // 我们通过寻找 PPackage 来确定总功耗。
                if diff > 0 {
                    powerMap[name] = diff
                }
            }
            return 0
        }
        return 0
    }
    
    for (k, v) in powerMap {
        // 在 M4 上，PPackage 或 PSystem 是我们要的
        // 系数调整：IOReport 能量差值通常需要经过频率基准校准
        // 典型值在 1000000 左右对应 1W
        if k.contains("PPackage") || k.contains("PSystem") || k.contains("PDRAM") {
            print("Channel: \(k) | Raw Delta: \(v)")
        }
    }
}

getAccurateM4Power()
