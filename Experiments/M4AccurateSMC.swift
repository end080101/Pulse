import Foundation
import IOKit

// 严格遵循 AppleSMC 协议的结构体
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

class M4HardwareReader {
    private var connection: io_connect_t = 0
    
    init() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        if service != 0 {
            IOServiceOpen(service, mach_task_self_, 0, &connection)
            IOObjectRelease(service)
        }
    }
    
    deinit {
        if connection != 0 { IOServiceClose(connection) }
    }
    
    func getPower(key: String) -> Double? {
        let keyInt = key.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
        var input = SMCParam_t()
        input.key = keyInt
        input.data8 = 5 // SMC_CMD_READ_BYTES
        
        var output = SMCParam_t()
        var outSize = MemoryLayout<SMCParam_t>.stride
        
        let result = IOConnectCallStructMethod(connection, 2, &input, MemoryLayout<SMCParam_t>.stride, &output, &outSize)
        
        if result == kIOReturnSuccess {
            // M4 的功耗数据存放在 bytes 的前 4 个字节
            let b = output.bytes
            let byteData = [b.0, b.1, b.2, b.3]
            let watts = byteData.withUnsafeBytes { $0.load(as: Float32.self) }
            return Double(watts)
        }
        return nil
    }
}

let reader = M4HardwareReader()
print("M4 Accurate Hardware Power Scan:")
// PDTR 是 DC 输入总功率，PSTR 是整机功率，Ppt0 是 SoC 封装功率
for k in ["PDTR", "PSTR", "Ppt0"] {
    if let val = reader.getPower(key: k) {
        print("\(k): \(String(format: "%.2f", val)) W")
    } else {
        print("\(k): Failed to read")
    }
}
