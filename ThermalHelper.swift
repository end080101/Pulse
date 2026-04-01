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

// 1. Core logic
func getTemp() -> Double {
    guard let client = IOHIDEventSystemClientCreateWithType(nil, 1, 0) else { return 0.0 }
    let match = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 0x0005] as CFDictionary
    IOHIDEventSystemClientSetMatching(client, match)
    var maxTemp = 0.0
    if let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject] {
        for service in services {
            if let event = IOHIDServiceClientCopyEvent(service, 15, 0, 0) {
                let temp = IOHIDEventGetFloatValue(event, 0x0f0000)
                if temp > maxTemp && temp < 150 { maxTemp = temp }
            }
        }
    }
    return maxTemp
}

func getPower() -> Double {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/powermetrics")
    task.arguments = ["--samplers", "cpu_power,gpu_power", "-i", "500", "-n", "1"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    try? task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    if let str = String(data: data, encoding: .utf8) {
        if let range = str.range(of: #"Combined Power \(CPU \+ GPU \+ ANE\):\s*[0-9.]+"#, options: .regularExpression) {
            let parts = str[range].components(separatedBy: ":")
            if parts.count > 1 {
                let val = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "mW", with: "")
                return Double(val) ?? 0.0
            }
        }
    }
    return 0.0
}

// Main Loop
while true {
    let t = getTemp()
    let p = getPower()

    print("DATA|TEMP:\(t)|PACKAGE_MW:\(p)")
    fflush(stdout)

    Thread.sleep(forTimeInterval: 2.0)
}
