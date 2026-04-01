import Foundation

enum DeviceIconResolver {
    static func iconName(for name: String) -> String {
        let normalized = name.lowercased()
        if normalized.contains("airpods") || normalized.contains("headphone") || normalized.contains("headset") || normalized.contains("ear") {
            return "headphones"
        }
        if normalized.contains("mouse") || normalized.contains("滑鼠") || normalized.contains("鼠标") || normalized.contains("鼠") {
            return "cursorarrow"
        }
        if normalized.contains("keyboard") || normalized.contains("键盘") {
            return "keyboard.fill"
        }
        if normalized.contains("trackpad") || normalized.contains("触控板") {
            return "magictrackpad.fill"
        }
        if normalized.contains("watch") || normalized.contains("手表") {
            return "applewatch"
        }
        return "bluetooth"
    }
}
