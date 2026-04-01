import Foundation
import IOKit

struct SMCKeyData {
    var key: UInt32 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

func readSMCValue(_ conn: io_connect_t, _ keyStr: String) {
    var input = SMCKeyData()
    input.key = 0
    for char in keyStr.utf8 { input.key = (input.key << 8) | UInt32(char) }
    input.data8 = 9
    var output = SMCKeyData()
    var outSize = MemoryLayout<SMCKeyData>.stride
    let res = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCKeyData>.stride, &output, &outSize)
    if res == kIOReturnSuccess {
        let b = output.bytes
        // 尝试两种解析：SP78 和 Float
        let spVal = Double(b.0) + Double(b.1) / 256.0
        let bytes = [b.0, b.1, b.2, b.3]
        let fltVal = bytes.withUnsafeBytes { $0.load(as: Float32.self) }
        print("KEY: \(keyStr) | SP78: \(spVal) | FLOAT: \(fltVal)")
    }
}

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
var conn: io_connect_t = 0
if service != 0 && IOServiceOpen(service, mach_task_self_, 0, &conn) == KERN_SUCCESS {
    // M4 新一代功耗 Key
    let keys = ["Ppt0", "Prc0", "Pgp0", "Pnt0", "Pld0", "Ptot"]
    for k in keys { readSMCValue(conn, k) }
    IOServiceClose(conn)
}
