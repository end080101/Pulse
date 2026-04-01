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

func bruteForcePowerSensors() {
    print("M4 Power brute-force: Scanning all 0xFF08 usage pages...")
    guard let client = IOHIDEventSystemClientCreateWithType(nil, 1, 0) else { return }
    let match = ["PrimaryUsagePage": 0xff08] as CFDictionary
    IOHIDEventSystemClientSetMatching(client, match)
    Thread.sleep(forTimeInterval: 0.5)
    
    guard let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject] else { return }
    
    for service in services {
        let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ?? "Unknown"
        // 尝试电力事件的所有常见 Field ID
        if let event = IOHIDServiceClientCopyEvent(service, 14, 0, 0) {
            // 在 M4 上，功耗可能藏在 0x0e0000 到 0x0e0005 之间
            for i in 0..<5 {
                let field = UInt32(0x0e0000 | i)
                let val = IOHIDEventGetFloatValue(event, field)
                if val > 0.1 {
                    print("Sensor: [\(name)] Field: \(String(format: "0x%08X", field)) -> \(val) W")
                }
            }
        }
    }
}

bruteForcePowerSensors()
