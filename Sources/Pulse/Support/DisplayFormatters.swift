import Foundation

enum DisplayFormatters {
    static func networkSpeed(_ kilobytesPerSecond: Double) -> String {
        if kilobytesPerSecond > 1024 {
            return String(format: "%.1f MB/s", kilobytesPerSecond / 1024)
        }
        return String(format: "%.0f KB/s", kilobytesPerSecond)
    }

    static func wifiLabel(_ ssid: String) -> String {
        ssid == "No WiFi" ? "No WiFi / Wired" : ssid
    }
}
