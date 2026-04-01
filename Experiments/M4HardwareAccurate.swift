import Foundation
import Darwin

// 彻底绕过 SMC，使用 libIOReport 读取 M4 真实的 PPackage (封装总功耗)
typealias IOReportCopyChannelsInGroup = @convention(c) (CFString?, CFString?, UInt64, UInt64, UInt64) -> Unmanaged<CFDictionary>?
typealias IOReportCreateSamples = @convention(c) (CFDictionary, CFDictionary?, UnsafeRawPointer?) -> Unmanaged<CFDictionary>?
typealias IOReportIterate = @convention(c) (CFDictionary, @convention(block) (UnsafeRawPointer) -> Int32) -> Int32
typealias IOReportSimpleGetRawValue = @convention(c) (UnsafeRawPointer, Int32) -> Int64
typealias IOReportChannelGetChannelName = @convention(c) (UnsafeRawPointer) -> Unmanaged<CFString>?

func getM4HardwarePower() {
    guard let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_NOW) else { return }
    let copyCh = unsafeBitCast(dlsym(handle, "IOReportCopyChannelsInGroup"), to: IOReportCopyChannelsInGroup.self)
    let createSamples = unsafeBitCast(dlsym(handle, "IOReportCreateSamples"), to: IOReportCreateSamples.self)
    let iterate = unsafeBitCast(dlsym(handle, "IOReportIterate"), to: IOReportIterate.self)
    let getVal = unsafeBitCast(dlsym(handle, "IOReportSimpleGetRawValue"), to: IOReportSimpleGetRawValue.self)
    let getName = unsafeBitCast(dlsym(handle, "IOReportChannelGetChannelName"), to: IOReportChannelGetChannelName.self)
    
    // 在 M4 上，总功耗由 "PPackage" 通道报告，它属于 "Energy Model" 组
    guard let channels = copyCh("Energy Model" as CFString, nil, 0, 0, 0)?.takeRetainedValue() else {
        print("M4 Error: Energy Model group hidden")
        return
    }
    
    print("M4 Physical Hardware Monitor (Sampling 1s)...")
    guard let s1 = createSamples(channels, nil, nil)?.takeRetainedValue() else { return }
    Thread.sleep(forTimeInterval: 1.0)
    guard let s2 = createSamples(channels, nil, nil)?.takeRetainedValue() else { return }
    
    _ = iterate(s2) { p2 in
        let name = getName(p2)?.takeRetainedValue() as String? ?? ""
        if name == "PPackage" || name == "PSystem" || name == "PDRAM" {
            let v2 = getVal(p2, 0)
            _ = iterate(s1) { p1 in
                if (getName(p1)?.takeRetainedValue() as String?) == name {
                    let v1 = getVal(p1, 0)
                    // 在 M4 上，差值即为微焦耳能量消耗，1s 采样下 diff / 1e6 即为真实瓦特
                    let watts = Double(v2 - v1) / 1_000_000.0
                    if watts > 0.1 {
                        print("M4_REAL_HARDWARE [\(name)]: \(String(format: "%.2f", watts)) W")
                    }
                }
                return 0
            }
        }
        return 0
    }
}

getM4HardwarePower()
