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

func scanPowerSensors() {
    print("Scanning M4 Power Sensors (Page 0xFF08)...")
    guard let client = IOHIDEventSystemClientCreateWithType(nil, 1, 0) else { return }
    
    // 0xFF08 是 Power/Voltage/Current 页面
    let match = ["PrimaryUsagePage": 0xff08] as CFDictionary
    IOHIDEventSystemClientSetMatching(client, match)
    Thread.sleep(forTimeInterval: 0.5)
    
    guard let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject] else { 
        print("No Power services found.")
        return 
    }
    
    print("Found \(services.count) potential power sensors.")
    for service in services {
        let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ?? "Unknown"
        // 尝试不同的事件类型 (14 是 Power, 12 是 Current, 13 是 Voltage)
        for type in [12, 13, 14] {
            if let event = IOHIDServiceClientCopyEvent(service, Int64(type), 0, 0) {
                let val = IOHIDEventGetFloatValue(event, UInt32(type << 16))
                if val != 0 {
                    print("Sensor: [\(name)] Type: \(type) -> Value: \(val)")
                }
            }
        }
    }
}

scanPowerSensors()
