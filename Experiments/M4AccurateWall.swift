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

func getM4WallPower() {
    print("M4 Wall Power Engine: Searching for hidden Total Power sensors...")
    guard let client = IOHIDEventSystemClientCreateWithType(nil, 1, 0) else { return }
    
    // M4 真正的总功耗页面 0xFF08, Usage 0x0005 (Power Delivery)
    let match = [
        "PrimaryUsagePage": 0xff08,
        "PrimaryUsage": 0x0005
    ] as CFDictionary
    
    IOHIDEventSystemClientSetMatching(client, match)
    Thread.sleep(forTimeInterval: 0.5)
    
    guard let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject] else { 
        print("M4 Error: Hardware power sensors restricted by OS")
        return 
    }
    
    for service in services {
        let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ?? "Unknown"
        // 14 是 Power Event
        if let event = IOHIDServiceClientCopyEvent(service, 14, 0, 0) {
            // M4 的总瓦特通常在 Field 0x0e0001
            let watts = IOHIDEventGetFloatValue(event, 0x0e0001)
            if watts > 0.1 {
                print(">>> M4 ACCURATE PHYSICAL POWER [\(name)]: \(watts) W")
            }
        }
    }
}

getM4WallPower()
