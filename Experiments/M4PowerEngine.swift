import Foundation
import IOKit

@_silgen_name("IOHIDEventSystemClientCreateWithType")
func IOHIDEventSystemClientCreateWithType(_ allocator: CFAllocator?, _ type: Int32, _ flags: UInt32) -> AnyObject?

@_silgen_name("IOHIDEventSystemClientSetMatching")
func IOHIDEventSystemClientSetMatching(_ client: AnyObject, _ match: CFDictionary)

@_silgen_name("IOHIDEventSystemClientCopyServices")
func IOHIDEventSystemClientCopyServices(_ client: AnyObject) -> CFArray?

@_silgen_name("IOHIDServiceClientCopyEvent")
func IOHIDServiceClientCopyEvent(_ service: AnyObject, _ eventType: Int64, _ flags: Int32, _ options: Int32) -> AnyObject?

@_silgen_name("IOHIDEventGetFloatValue")
func IOHIDEventGetFloatValue(_ event: AnyObject, _ field: UInt32) -> Double

@_silgen_name("IOHIDServiceClientCopyProperty")
func IOHIDServiceClientCopyProperty(_ service: AnyObject, _ property: CFString) -> AnyObject?

func getM4TotalPower() {
    print("M4 Power Engine: Identifying Rail Sensors...")
    guard let client = IOHIDEventSystemClientCreateWithType(nil, 1, 0) else { return }
    let match = ["PrimaryUsagePage": 0xff08] as CFDictionary
    IOHIDEventSystemClientSetMatching(client, match)
    Thread.sleep(forTimeInterval: 0.5)
    
    guard let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject] else { return }
    
    var totalW = 0.0
    for service in services {
        let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ?? ""
        
        // 我们寻找特殊的输入功率传感器，或者累加主要的 Buck 轨道
        // 在 M4 上，通常会有类似 "System Power" 或 "Input Power" 的 HID 导出
        // 或者是多个 ibuck (电流) 传感器的总和
        
        // 尝试直接读取 Power 事件 (Type 14)
        if let event = IOHIDServiceClientCopyEvent(service, 14, 0, 0) {
            let val = IOHIDEventGetFloatValue(event, 0x0e0001) // Power field
            if val > 0.1 {
                print("Rail [\(name)]: \(val) W")
                // 如果发现 System Power 或 Total Power，这就是我们要找的
                if name.contains("System") || name.contains("Total") {
                    print(">>> FOUND MAIN SENSOR: \(val) W")
                }
            }
        }
    }
}

getM4TotalPower()
