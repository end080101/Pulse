import Foundation
import IOKit

// 严格参考 Stats 开源项目的 SMC 结构体
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

func readM4TotalPower() {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
    guard service != 0 else { return }
    
    var conn: io_connect_t = 0
    guard IOServiceOpen(service, mach_task_self_, 0, &conn) == KERN_SUCCESS else { return }
    
    // PDTR 是 M4 Mac mini 报告整机总功耗的核心 Key
    let keyStr = "PDTR"
    var input = SMCParam_t()
    input.key = 0
    for char in keyStr.utf8 { input.key = (input.key << 8) | UInt32(char) }
    
    // 第一步：获取 Key 信息（大小和类型）
    input.data8 = 9 // SMC_CMD_READ_KEYINFO
    var output = SMCParam_t()
    var outSize = MemoryLayout<SMCParam_t>.stride
    
    let res1 = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCParam_t>.stride, &output, &outSize)
    
    if res1 == kIOReturnSuccess {
        let size = output.keyInfo.dataSize
        // 第二步：使用 READ_BYTES (5) 读取真实数值
        input.data8 = 5 
        input.keyInfo.dataSize = size
        
        let res2 = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCParam_t>.stride, &output, &outSize)
        if res2 == kIOReturnSuccess {
            let b = output.bytes
            let data = [b.0, b.1, b.2, b.3]
            // M4 的功耗通常是 'flt ' (Float32) 类型
            let watts = data.withUnsafeBytes { $0.load(as: Float32.self) }
            print("ACCURATE_POWER: \(watts) W")
        }
    }
    
    IOServiceClose(conn)
}

readM4TotalPower()
