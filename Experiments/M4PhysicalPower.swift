import Foundation
import Darwin

typealias IOReportCopyChannelsInGroup = @convention(c) (CFString?, CFString?, UInt64, UInt64, UInt64) -> Unmanaged<CFDictionary>?
typealias IOReportCreateSamples = @convention(c) (CFDictionary, CFDictionary?, UnsafeRawPointer?) -> Unmanaged<CFDictionary>?
typealias IOReportIterate = @convention(c) (CFDictionary, @convention(block) (UnsafeRawPointer) -> Int32) -> Int32
typealias IOReportSimpleGetRawValue = @convention(c) (UnsafeRawPointer, Int32) -> Int64
typealias IOReportChannelGetChannelName = @convention(c) (UnsafeRawPointer) -> Unmanaged<CFString>?

func getM4PhysicalPower() {
    guard let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_NOW) else { return }
    let copyCh = unsafeBitCast(dlsym(handle, "IOReportCopyChannelsInGroup"), to: IOReportCopyChannelsInGroup.self)
    let createSamples = unsafeBitCast(dlsym(handle, "IOReportCreateSamples"), to: IOReportCreateSamples.self)
    let iterate = unsafeBitCast(dlsym(handle, "IOReportIterate"), to: IOReportIterate.self)
    let getVal = unsafeBitCast(dlsym(handle, "IOReportSimpleGetRawValue"), to: IOReportSimpleGetRawValue.self)
    let getName = unsafeBitCast(dlsym(handle, "IOReportChannelGetChannelName"), to: IOReportChannelGetChannelName.self)
    
    // 针对 M4 的 "Energy Model" 组
    guard let channels = copyCh("Energy Model" as CFString, nil, 0, 0, 0)?.takeRetainedValue() else { return }
    
    print("Reading Physical Power from [Energy Model]...")
    guard let s1 = createSamples(channels, nil, nil)?.takeRetainedValue() else { return }
    Thread.sleep(forTimeInterval: 1.0)
    guard let s2 = createSamples(channels, nil, nil)?.takeRetainedValue() else { return }
    
    var totalW = 0.0
    _ = iterate(s2) { ptr2 in
        let name = getName(ptr2)?.takeRetainedValue() as String? ?? ""
        let v2 = getVal(ptr2, 0)
        
        _ = iterate(s1) { ptr1 in
            let name1 = getName(ptr1)?.takeRetainedValue() as String? ?? ""
            if name == name1 {
                let v1 = getVal(ptr1, 0)
                let diff = Double(v2 - v1)
                
                // IOReport 能量差值转换为瓦特
                // 对应 M4 的 PPackage (封装总功耗) 或 PSystem
                if diff > 0 {
                    let w = diff / 1_000_000.0 // 假设单位是微焦耳，1s 间隔
                    if name.contains("PPackage") || name.contains("PSystem") {
                        print("FOUND ACCURATE \(name): \(w) W")
                        totalW = w
                    } else if name.contains("PDRAM") || name.contains("PCPU") {
                        print("Sub-component \(name): \(w) W")
                    }
                }
            }
            return 0
        }
        return 0
    }
}

getM4PhysicalPower()
