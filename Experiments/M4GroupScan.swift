import Foundation
import Darwin

func dumpAllIOReportGroups() {
    guard let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_NOW) else { return }
    let copyAll = unsafeBitCast(dlsym(handle, "IOReportCopyAllChannels"), to: (@convention(c) (UInt64, UInt64, UInt64) -> Unmanaged<CFDictionary>?).self)
    let getGrp = unsafeBitCast(dlsym(handle, "IOReportChannelGetGroup"), to: (@convention(c) (UnsafeRawPointer) -> Unmanaged<CFString>?).self)
    let getName = unsafeBitCast(dlsym(handle, "IOReportChannelGetChannelName"), to: (@convention(c) (UnsafeRawPointer) -> Unmanaged<CFString>?).self)
    
    print("Dumping all available IOReport groups on M4...")
    guard let allChannels = copyAll(0, 0, 0)?.takeRetainedValue() as? [String: Any],
          let channels = allChannels["IOReportChannels"] as? [Any] else { return }
    
    var groups = Set<String>()
    for ch in channels {
        let ptr = UnsafeRawPointer(Unmanaged.passUnretained(ch as CFTypeRef).toOpaque())
        if let g = getGrp(ptr)?.takeRetainedValue() as String? {
            groups.insert(g)
        }
    }
    
    for g in groups.sorted() {
        if g.lowercased().contains("pwr") || g.lowercased().contains("energy") || g.lowercased().contains("power") || g.lowercased().contains("sys") {
            print("Found Group: \(g)")
        }
    }
}

dumpAllIOReportGroups()
