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

func getSSID() -> String {
    let nodes = ["AppleBCMWLANSkywalkInterface", "AppleBCMWLANCore", "Apple80211Interface"]
    for node in nodes {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        task.arguments = ["-n", node, "-r", "-l"]
        let pipe = Pipe(); task.standardOutput = pipe
        try? task.run(); task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let lines = output.components(separatedBy: .newlines)
            for line in lines where line.contains("IO80211SSID") {
                if let range = line.range(of: " = \"") {
                    let ssid = line[range.upperBound...].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !ssid.isEmpty && ssid != "<redacted>" { return ssid }
                }
            }
        }
    }
    return "No WiFi"
}

// Main Loop
var count = 0
while true {
    let t = getTemp()
    let p = getPower()
    var s = ""
    if count % 5 == 0 { s = getSSID() }
    
    print("DATA|TEMP:\(t)|PACKAGE_MW:\(p)\(s.isEmpty ? "" : "|SSID:\(s)")")
    fflush(stdout)
    
    count += 1
    Thread.sleep(forTimeInterval: 2.0)
}
