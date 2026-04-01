import Foundation
import IOKit

enum BluetoothMonitor {
    static func refresh() -> [BluetoothDeviceInfo] {
        var devices: [String: Int] = [:]
        let batteryKeys = ["BatteryPercent", "BatteryPercentSingle", "BatteryPercentCombined", "BatteryPercentLeft", "BatteryPercentRight"]
        let serviceTypes = ["AppleDeviceManagementHIDEventService", "AppleBluetoothHIDDevice", "IOBluetoothDevice"]

        for type in serviceTypes {
            let matching = IOServiceMatching(type)
            var iterator: io_iterator_t = 0

            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
                continue
            }

            var service = IOIteratorNext(iterator)
            while service != 0 {
                let name = resolvedName(for: service) ?? "Generic Device"
                for key in batteryKeys {
                    if let battery = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int,
                       battery > 0,
                       battery <= 100 {
                        devices[name] = max(devices[name] ?? 0, battery)
                    }
                }

                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }

        return devices
            .filter { $0.key != "Generic Device" }
            .map { BluetoothDeviceInfo(name: $0.key, battery: $0.value) }
            .sorted { $0.name < $1.name }
    }

    private static func resolvedName(for service: io_registry_entry_t) -> String? {
        if let product = IORegistryEntryCreateCFProperty(service, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return product
        }

        if let name = IORegistryEntryCreateCFProperty(service, "DeviceName" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return name
        }

        var parent: io_registry_entry_t = 0
        guard IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(parent) }

        return IORegistryEntryCreateCFProperty(parent, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
    }
}
