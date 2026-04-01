import AppKit
import SwiftUI
import Combine
import ImageIO

class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var monitor: SystemMonitor
    private var cancellables = Set<AnyCancellable>()
    private var animationTimer: Timer?
    private var gifFrames: [NSImage] = []
    private var processResizeWorkItem: DispatchWorkItem?
    
    init(monitor: SystemMonitor) {
        self.monitor = monitor
        super.init()
        loadGifFrames()
        setupStatusItem()
        setupPopover()
        setupBindings()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            
            // Set a base image to ensure the button has existence even before timer fires
            if let firstFrame = gifFrames.first {
                let aspect = firstFrame.size.width / firstFrame.size.height
                statusItem.length = NSStatusBar.system.thickness * aspect
                button.image = firstFrame
            } else {
                statusItem.length = 24
            }
            updateLogo(monitor.logoType)
        }
    }
    
    private func loadGifFrames() {
        // Try Bundle.module first (SPM default)
        var url = Bundle.module.url(forResource: "icon", withExtension: "gif")
        
        if url == nil {
            // Fallback for packaged app structure
            url = Bundle.main.url(forResource: "icon", withExtension: "gif", subdirectory: "Pulse_Pulse.bundle")
        }
        
        if url == nil {
            // Direct path fallback
            if let resPath = Bundle.main.resourcePath {
                let path = "\(resPath)/Pulse_Pulse.bundle/icon.gif"
                if FileManager.default.fileExists(atPath: path) {
                    url = URL(fileURLWithPath: path)
                }
            }
        }
        
        guard let finalUrl = url else {
            print("Error: icon.gif not found anywhere")
            return
        }
        
        guard let source = CGImageSourceCreateWithURL(finalUrl as CFURL, nil) else {
            return
        }
        
        let count = CGImageSourceGetCount(source)
        gifFrames = (0..<count).compactMap { i in
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { return nil }
            let img = NSImage(cgImage: cgImage, size: NSSize(width: 100, height: 100))
            img.isTemplate = true
            return img
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(monitor: monitor))
    }
    
    private func updateLogo(_ type: String) {
        animationTimer?.invalidate()
        
        var frame: CGFloat = 0
        var gifIdx = 0
        let barHeight = NSStatusBar.system.thickness
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if type == "gif" && !self.gifFrames.isEmpty {
                let img = self.gifFrames[gifIdx]
                let aspect = img.size.width / img.size.height
                let targetWidth = barHeight * aspect
                
                self.statusItem.length = targetWidth
                self.statusItem.button?.image = img
                
                gifIdx = (gifIdx + 1) % self.gifFrames.count
                return
            }
            
            frame += 0.1
            if frame > 1.0 { frame = 0 }
            
            let baseSize = NSSize(width: 24, height: barHeight)
            let finalImg = NSImage(size: baseSize)
            finalImg.lockFocus()
            let center = NSPoint(x: 12, y: barHeight / 2)
            
            if type == "antenna.radiowaves.left.and.right" {
                for i in 0..<3 {
                    let progress = (CGFloat(i) * 0.33 + frame).truncatingRemainder(dividingBy: 1.0)
                    let radius = progress * 10.0
                    let opacity = 1.0 - progress
                    
                    let rect = NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    let path = NSBezierPath(ovalIn: rect)
                    NSColor.controlAccentColor.withAlphaComponent(opacity).setStroke()
                    path.lineWidth = 1.5
                    path.stroke()
                }
                let dot = NSBezierPath(ovalIn: NSRect(x: 10.5, y: (barHeight/2)-1.5, width: 3, height: 3))
                NSColor.labelColor.setFill()
                dot.fill()
            } else if type == "fan.fill" {
                let fanImg = NSImage(systemSymbolName: "fan.fill", accessibilityDescription: nil)?
                    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 18, weight: .black))
                self.drawRotated(fanImg!, center: center, angle: -frame * .pi * 2)
            } else {
                let scale = 0.95 + abs(sin(frame * .pi)) * 0.15
                let img = NSImage(systemSymbolName: type, accessibilityDescription: nil)?
                    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 18 * scale, weight: .black))
                img?.draw(at: NSPoint(x: center.x - (img?.size.width ?? 0)/2, y: center.y - (img?.size.height ?? 0)/2), from: .zero, operation: .sourceOver, fraction: 1.0)
            }
            finalImg.unlockFocus()
            finalImg.isTemplate = true
            self.statusItem.length = baseSize.width
            self.statusItem.button?.image = finalImg
        }
    }
    
    private func drawRotated(_ image: NSImage, center: NSPoint, angle: CGFloat) {
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byRadians: angle)
        transform.translateX(by: -image.size.width/2, yBy: -image.size.height/2)
        transform.concat()
        image.draw(at: .zero, from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: .sourceOver, fraction: 1.0)
    }
    
    private func setupBindings() {
        monitor.$logoType.sink { [weak self] t in self?.updateLogo(t) }.store(in: &cancellables)

        monitor.$isProcessesExpanded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isExpanded in
                guard let self = self, self.popover.isShown else { return }
                self.processResizeWorkItem?.cancel()

                if isExpanded {
                    DispatchQueue.main.async {
                        self.updatePopoverSize(animated: false)
                    }
                } else {
                    self.updatePopoverSize(animated: false)
                }
            }
            .store(in: &cancellables)
    }

    private func updatePopoverSize(animated: Bool) {
        guard let controller = popover.contentViewController else { return }

        DispatchQueue.main.async {
            controller.view.layoutSubtreeIfNeeded()
            let size = controller.view.fittingSize

            if animated, let window = controller.view.window {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.18
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().setContentSize(size)
                }
            } else {
                self.popover.contentSize = size
            }
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                updatePopoverSize(animated: false)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
