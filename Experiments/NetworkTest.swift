import Foundation

func getBytes() -> (UInt64, UInt64) {
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return (0, 0) }
    var currentIn: UInt64 = 0
    var currentOut: UInt64 = 0
    var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
    while ptr != nil {
        let interface = ptr!.pointee
        let flags = Int32(interface.ifa_flags)
        let name = String(cString: interface.ifa_name)
        if (flags & 0x1) != 0 && (flags & 0x40) != 0 && (flags & 0x8) == 0 { // IFF_UP, IFF_RUNNING, !IFF_LOOPBACK
            if name.hasPrefix("en") || name.hasPrefix("utun") {
                if let data = interface.ifa_data {
                    let ifData = data.assumingMemoryBound(to: if_data.self)
                    currentIn += UInt64(ifData.pointee.ifi_ibytes)
                    currentOut += UInt64(ifData.pointee.ifi_obytes)
                }
            }
        }
        ptr = interface.ifa_next
    }
    freeifaddrs(ifaddr)
    return (currentIn, currentOut)
}

print("Testing Network Logic (Wait 5s)...")
let (in1, out1) = getBytes()
Thread.sleep(forTimeInterval: 5.0)
let (in2, out2) = getBytes()

let diffIn = Double(in2 - in1) / 5.0 / 1024.0
let diffOut = Double(out2 - out1) / 5.0 / 1024.0

print(String(format: "System Speed: Down %.2f KB/s, Up %.2f KB/s", diffIn, diffOut))
