import Foundation
import IOKit

// 尝试从 AppleSMC 读取整机功耗相关的 Key
struct SMCKeyData {
    var key: UInt32 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

func readSMCKey(_ conn: io_connect_t, _ keyStr: String) -> Double? {
    var input = SMCKeyData()
    input.key = 0
    for char in keyStr.utf8 { input.key = (input.key << 8) | UInt32(char) }
    input.data8 = 9 // READ_KEY
    
    var output = SMCKeyData()
    var outSize = MemoryLayout<SMCKeyData>.stride
    let res = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCKeyData>.stride, &output, &outSize)
    
    if res == kIOReturnSuccess {
        // 尝试解析为 SP78 或 Float
        let b = output.bytes
        let val = Double(b.0) + Double(b.1) / 256.0
        return val
    }
    return nil
}

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
var conn: io_connect_t = 0
if service != 0 && IOServiceOpen(service, mach_task_self_, 0, &conn) == KERN_SUCCESS {
    // PSTR = Total System Power (Watts) - 这是一个非常经典的 Key
    // PDTR = DC Total Power
    // PC0R = CPU Core Power
    let keys = ["PSTR", "PDTR", "PCPR", "PGPR", "PMTR"]
    print("SMC Power Scan:")
    for k in keys {
        if let val = readSMCKey(conn, k) {
            print("\(k): \(val) W")
        }
    }
    IOServiceClose(conn)
}
