import Foundation
import IOKit

struct SMCKeyData {
    var key: UInt32 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

func readSMCValue(_ conn: io_connect_t, _ keyStr: String) -> Double? {
    var input = SMCKeyData()
    input.key = 0
    for char in keyStr.utf8 { input.key = (input.key << 8) | UInt32(char) }
    input.data8 = 9
    var output = SMCKeyData()
    var outSize = MemoryLayout<SMCKeyData>.stride
    let res = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCKeyData>.stride, &output, &outSize)
    if res == kIOReturnSuccess {
        let b = output.bytes
        let val = Double(b.0) + Double(b.1) / 256.0
        return val
    }
    return nil
}

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
var conn: io_connect_t = 0
if service != 0 && IOServiceOpen(service, mach_task_self_, 0, &conn) == KERN_SUCCESS {
    print("Brute-forcing M4 Power Keys...")
    let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    // 扫描所有 P 开头的 4 位 Key (Pxxx)
    for c1 in "ST" { // 优先扫描 PSxx, PTxx
        for c2 in letters {
            for c3 in letters {
                let key = "P\(c1)\(c2)\(c3)"
                if let val = readSMCValue(conn, key) {
                    if val > 2.0 && val < 150.0 {
                        print("FOUND POWER KEY: \(key) -> \(val) W")
                    }
                }
            }
        }
    }
    IOServiceClose(conn)
}
