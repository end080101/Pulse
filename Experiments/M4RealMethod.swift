import Foundation
import IOKit

// 严格参考 Stats 开源项目的 64 位对齐结构体
struct SMCKeyData_keyInfo_t {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

struct SMCKeyData_t {
    var key: UInt32 = 0
    var vers = UInt32(0) // 简化处理
    var pLimitData = UInt32(0) // 简化处理
    var keyInfo = SMCKeyData_keyInfo_t()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var padding: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

func readM4RealPower(keyStr: String) -> Double? {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
    var conn: io_connect_t = 0
    guard IOServiceOpen(service, mach_task_self_, 0, &conn) == KERN_SUCCESS else { return nil }
    defer { IOServiceClose(conn) }
    
    let keyInt = keyStr.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
    var input = SMCKeyData_t()
    input.key = keyInt
    
    // 1. 获取 KeyInfo (Selector 9)
    input.data8 = 9 
    var output = SMCKeyData_t()
    var outSize = MemoryLayout<SMCKeyData_t>.stride
    
    let res1 = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCKeyData_t>.stride, &output, &outSize)
    if res1 == KERN_SUCCESS {
        // 2. 读取 Bytes (Selector 5)
        let size = output.keyInfo.dataSize
        input.data8 = 5
        input.keyInfo.dataSize = size
        
        let res2 = IOConnectCallStructMethod(conn, 2, &input, MemoryLayout<SMCKeyData_t>.stride, &output, &outSize)
        if res2 == KERN_SUCCESS {
            let b = output.bytes
            // M4 的功耗是 'flt ' 类型 (4 字节 Float)
            if output.keyInfo.dataType == 0x666c7420 {
                var val: Float32 = 0
                memcpy(&val, [b.0, b.1, b.2, b.3], 4)
                return Double(val)
            }
            // 如果是 'sp78' 类型 (旧款)
            return Double(b.0) + Double(b.1) / 256.0
        }
    }
    return nil
}

print("Probing M4 via Stats-Method...")
if let pstr = readM4RealPower(keyStr: "PSTR") { print("PSTR (System Total): \(pstr) W") }
if let pdtr = readM4RealPower(keyStr: "PDTR") { print("PDTR (DC Total): \(pdtr) W") }
if let ppct = readM4RealPower(keyStr: "PPackage") { print("PPackage: \(ppct) W") }
