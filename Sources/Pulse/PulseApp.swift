import SwiftUI
import AppKit

@main
struct PulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var monitor: SystemMonitor!
    var menuBarManager: MenuBarManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = SystemMonitor()
        menuBarManager = MenuBarManager(monitor: monitor)
        
        NSApp.setActivationPolicy(.accessory)
    }
}
