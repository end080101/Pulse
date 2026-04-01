import Foundation
import IOKit

struct SMCParam_t {
    var key: UInt32 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    struct KeyInfo_t {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }
    var keyInfo = KeyInfo_t()
}

func readAccurateM4(keyStr: String) {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
    var conn: io_connect_t = 0
    IOServiceOpen(service, mach_task_self_, 0, &conn)
    
    let keyInt = keyStr.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
    var input = SMCParam_t()
    input.key = keyInt
    
    // 第一步：必须先读取 KeyInfo
    input.data8 = 9 // CMD_GET_KEYINFO
    var output = SMCParam_t()
    var outSize = MemoryLayout<SMCParam_t>.stride
    
    let res1 = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCParam_t>.stride, &output, &outSize)
    if res1 == KERN_SUCCESS {
        // 第二步：使用获取到的大小读取 Bytes
        let info = output.keyInfo
        input.data8 = 5 // CMD_READ_BYTES
        input.keyInfo.dataSize = info.dataSize
        
        let res2 = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCParam_t>.stride, &output, &outSize)
        if res2 == KERN_SUCCESS {
            let b = output.bytes
            // M4 Power Keys 通常是 flt (float) 类型
            let val = [b.0, b.1, b.2, b.3].withUnsafeBytes { $0.load(as: Float32.self) }
            print("M4_PHYSICAL_ACCURATE [\(keyStr)]: \(val) W")
        }
    }
    IOServiceClose(conn)
}

print("Initiating M4 Hardware Deep Probe...")
readAccurateM4(keyStr: "PDTR") // DC Total
readAccurateM4(keyStr: "PSTR") // System Total
readAccurateM4(keyStr: "Ppt0") // SoC Package
