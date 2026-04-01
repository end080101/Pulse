import Foundation
import Darwin

// 彻底的 IOReport 暴力扫描：不看名字，只看数值
typealias IOReportCopyAllChannels = @convention(c) (UInt64, UInt64, UInt64) -> Unmanaged<CFDictionary>?
typealias IOReportCreateSamples = @convention(c) (CFDictionary, CFDictionary?, UnsafeRawPointer?) -> Unmanaged<CFDictionary>?
typealias IOReportIterate = @convention(c) (CFDictionary, @convention(block) (UnsafeRawPointer) -> Int32) -> Int32
typealias IOReportSimpleGetRawValue = @convention(c) (UnsafeRawPointer, Int32) -> Int64
typealias IOReportChannelGetChannelName = @convention(c) (UnsafeRawPointer) -> Unmanaged<CFString>?
typealias IOReportChannelGetGroup = @convention(c) (UnsafeRawPointer) -> Unmanaged<CFString>?

func findTheMissingSensor() {
    guard let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_NOW) else { return }
    let copyAll = unsafeBitCast(dlsym(handle, "IOReportCopyAllChannels"), to: IOReportCopyAllChannels.self)
    let createSamples = unsafeBitCast(dlsym(handle, "IOReportCreateSamples"), to: IOReportCreateSamples.self)
    let iterate = unsafeBitCast(dlsym(handle, "IOReportIterate"), to: IOReportIterate.self)
    let getVal = unsafeBitCast(dlsym(handle, "IOReportSimpleGetRawValue"), to: IOReportSimpleGetRawValue.self)
    let getName = unsafeBitCast(dlsym(handle, "IOReportChannelGetChannelName"), to: IOReportChannelGetChannelName.self)
    let getGrp = unsafeBitCast(dlsym(handle, "IOReportChannelGetGroup"), to: IOReportChannelGetGroup.self)
    
    guard let all = copyAll(0, 0, 0)?.takeRetainedValue() else { return }
    print("M4 Sensor Deep Scan (Identifying 8W-15W targets)...")
    
    guard let s1 = createSamples(all, nil, nil)?.takeRetainedValue() else { return }
    Thread.sleep(forTimeInterval: 1.0)
    guard let s2 = createSamples(all, nil, nil)?.takeRetainedValue() else { return }
    
    _ = iterate(s2) { p2 in
        let v2 = getVal(p2, 0)
        _ = iterate(s1) { p1 in
            let v1 = getVal(p1, 0)
            let diff = Double(v2 - v1)
            
            // 在 M4 上，差值通常是微焦耳
            // 目标功耗 8-15W 对应差值应在 8,000,000 - 15,000,000 左右
            if diff > 5_000_000 && diff < 100_000_000 {
                let name = getName(p2)?.takeRetainedValue() as String? ?? "Unknown"
                let grp = getGrp(p2)?.takeRetainedValue() as String? ?? "Unknown"
                print("POTENTIAL SENSOR: [\(grp)] \(name) -> \(diff / 1_000_000.0) W")
            }
            return 0
        }
        return 0
    }
}

findTheMissingSensor()
