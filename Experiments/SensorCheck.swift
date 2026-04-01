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

let client = IOHIDEventSystemClientCreateWithType(nil, 1, 0)
let match = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 0x0005] as CFDictionary
IOHIDEventSystemClientSetMatching(client!, match)
Thread.sleep(forTimeInterval: 0.5)

if let services = IOHIDEventSystemClientCopyServices(client!) as? [AnyObject] {
    print(String(format: "%-25s | %-10s", "SENSOR NAME", "TEMP (°C)"))
    print(String(repeating: "-", count: 40))
    for service in services {
        let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ?? "Unknown"
        if let event = IOHIDServiceClientCopyEvent(service, 15, 0, 0) {
            let temp = IOHIDEventGetFloatValue(event, 0x0f0000)
            if temp > 0 {
                print(String(format: "%-25s | %-10.2f", name, temp))
            }
        }
    }
}
