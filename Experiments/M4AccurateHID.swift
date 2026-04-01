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

func getM4PhysicalPower() {
    print("M4 Accurate Power Engine: Searching HID 0xFF08/0x0001...")
    guard let client = IOHIDEventSystemClientCreateWithType(nil, 1, 0) else { return }
    
    // 匹配 System Power 传感器
    let match = [
        "PrimaryUsagePage": 0xff08,
        "PrimaryUsage": 0x0001
    ] as CFDictionary
    
    IOHIDEventSystemClientSetMatching(client, match)
    Thread.sleep(forTimeInterval: 0.5)
    
    guard let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject] else { return }
    
    for service in services {
        let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ?? "Unknown"
        // 尝试获取 Power Event (Type 14)
        if let event = IOHIDServiceClientCopyEvent(service, 14, 0, 0) {
            // M4 的 Field ID 可能是 0x0e0001 或 0x0e0000
            let p1 = IOHIDEventGetFloatValue(event, 0x0e0001)
            let p2 = IOHIDEventGetFloatValue(event, 0x0e0000)
            let p = max(p1, p2)
            if p > 0.1 {
                print("FOUND PHYSICAL POWER [\(name)]: \(p) W")
            }
        }
    }
}

getM4PhysicalPower()
