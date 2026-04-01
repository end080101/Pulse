import Foundation

struct CPUStats {
    var usage: Double = 0.0
    var history: [Double] = Array(repeating: 0.0, count: 20)
    var temperature: Double = 0.0
}

struct MemoryStats {
    var usedGB: Double = 0.0
    var totalGB: Double = 0.0
}

struct GPUStats {
    var usage: Double = 0.0
}

struct PowerStats {
    var usageWatts: Double = 0.0
    var isMeasured: Bool = false
}

struct StorageStats {
    var usedGB: Double = 0.0
    var totalGB: Double = 0.0
    var health: Int = 100
}

struct NetworkStats {
    var downKBps: Double = 0.0
    var upKBps: Double = 0.0
    var downHistory: [Double] = Array(repeating: 0.0, count: 20)
    var upHistory: [Double] = Array(repeating: 0.0, count: 20)
    var pingLatency: Double = 0.0
    var localIPv4: String = "127.0.0.1"
    var localIPv6: String = ""
    var publicIP: String = "Fetching..."
    var wifiSSID: String = "Unknown"
}

struct BatteryStats {
    var level: Int = 0
    var isCharging: Bool = false
    var health: Int = 0
    var cycles: Int = 0
    var timeRemaining: String = "--:--"
    var hasBattery: Bool = false
}

struct BluetoothDeviceInfo: Identifiable, Hashable {
    let name: String
    let battery: Int

    var id: String { name }
}

struct ProcessStat: Identifiable, Hashable {
    let name: String
    let cpu: Double
    let memory: Double

    var id: String { name }
}

struct SystemSnapshot {
    var cpu = CPUStats()
    var memory = MemoryStats()
    var gpu = GPUStats()
    var power = PowerStats()
    var storage = StorageStats()
    var network = NetworkStats()
    var battery = BatteryStats()
    var bluetoothDevices: [BluetoothDeviceInfo] = []
    var topProcesses: [ProcessStat] = []
    var modelName: String
    var version: String
}
