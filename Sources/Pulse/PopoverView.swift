import SwiftUI

struct PopoverView: View {
    @ObservedObject var monitor: SystemMonitor
    @State private var processListHeight: CGFloat = 0
    @State private var processRevealProgress: CGFloat = 0
    @State private var isProcessBodyMounted: Bool = false
    @State private var processAnimationVersion: Int = 0
    
    // STRICT FONT SYSTEM
    private let sizeDisplay: CGFloat = 20
    private let sizeMetric: CGFloat = 14
    private let sizeBody: CGFloat = 9
    private let sizeCaption: CGFloat = 7
    private let compactCardHeight: CGFloat = 66
    
    var body: some View {
        VStack(spacing: 0) {
            BentoHeader(monitor: monitor)
            
            VStack(spacing: 10) {
                // 1. CPU - Hero Row
                BentoCard(title: "CPU & PERFORMANCE", icon: "cpu.fill", color: .blue) {
                    VStack(spacing: 8) {
                        HStack(alignment: .center, spacing: 15) {
                            CircularProgress(progress: monitor.snapshot.cpu.usage / 100, color: .blue, size: 36)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(String(format: "%.1f%%", monitor.snapshot.cpu.usage))
                                    .font(.system(size: sizeDisplay, weight: .bold, design: .rounded))
                                Text("OVERALL LOAD").font(.system(size: sizeCaption, weight: .bold)).foregroundColor(.secondary)
                            }
                            Spacer()
                            if monitor.snapshot.cpu.temperature > 0 {
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("\(Int(monitor.snapshot.cpu.temperature))°C")
                                        .font(.system(size: sizeMetric, weight: .bold, design: .rounded))
                                    Text("HOTSPOT").font(.system(size: sizeCaption, weight: .black)).foregroundColor(.secondary)
                                }
                            }
                        }
                        Sparkline(data: monitor.snapshot.cpu.history, color: .blue).frame(height: 20)
                    }
                }
                
                // 2. Memory, GPU & Power Row
                HStack(alignment: .top, spacing: 10) {
                    BentoCard(title: "RAM", icon: "memorychip.fill", color: .green) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f GB", monitor.snapshot.memory.usedGB))
                                .font(.system(size: sizeMetric, weight: .bold, design: .rounded))
                            CapsuleProgress(progress: monitor.snapshot.memory.totalGB > 0 ? monitor.snapshot.memory.usedGB / monitor.snapshot.memory.totalGB : 0, color: .green)
                            Text("of \(Int(monitor.snapshot.memory.totalGB)) GB").font(.system(size: sizeCaption, weight: .bold)).foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: compactCardHeight)

                    BentoCard(title: "GPU", icon: "display", color: .pink) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.0f%%", monitor.snapshot.gpu.usage))
                                .font(.system(size: sizeMetric, weight: .bold, design: .rounded))
                            CapsuleProgress(progress: monitor.snapshot.gpu.usage / 100.0, color: .pink)
                            Text("UTILIZATION").font(.system(size: sizeCaption, weight: .bold)).foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: compactCardHeight)
                     
                    BentoCard(title: "POWER", icon: "bolt.fill", color: .orange) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f W", monitor.snapshot.power.usageWatts))
                                .font(.system(size: sizeMetric, weight: .bold, design: .rounded)).foregroundColor(.orange)
                            CapsuleProgress(progress: min(monitor.snapshot.power.usageWatts / 35.0, 1.0), color: .orange)
                            Text(monitor.snapshot.power.isMeasured ? "POWERMETRICS PACKAGE" : "MODEL-BASED ESTIMATE").font(.system(size: sizeCaption, weight: .bold)).foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: compactCardHeight)
                }
                
                // 3. Battery Row (MacBook only)
                if monitor.snapshot.battery.hasBattery {
                    BentoCard(title: "BATTERY STATUS", icon: monitor.snapshot.battery.isCharging ? "bolt.batteryblock.fill" : "battery.100", color: .orange) {
                        HStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(monitor.snapshot.battery.level)%").font(.system(size: sizeMetric, weight: .bold, design: .rounded))
                                CapsuleProgress(progress: Double(monitor.snapshot.battery.level)/100.0, color: .orange)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(monitor.snapshot.battery.timeRemaining).font(.system(size: sizeMetric, weight: .bold, design: .rounded))
                                Text("Remaining").font(.system(size: sizeCaption, weight: .bold)).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 4. Network Row
                BentoCard(title: "NETWORK & CONNECTIVITY", icon: "network", color: .purple, trailing: {
                    PingIndicator(latency: monitor.snapshot.network.pingLatency)
                }) {
                    VStack(spacing: 8) {
                        VStack(spacing: 4) {
                            NetworkInfoRow(label: "SSID", value: DisplayFormatters.wifiLabel(monitor.snapshot.network.wifiSSID), icon: "wifi", fontSize: sizeBody)
                            NetworkInfoRow(label: "PUBLIC", value: monitor.snapshot.network.publicIP, icon: "globe", fontSize: sizeBody)
                            NetworkInfoRow(label: "IPv4", value: monitor.snapshot.network.localIPv4, icon: "network", fontSize: sizeBody)
                            NetworkInfoRow(label: "IPv6", value: monitor.snapshot.network.localIPv6.isEmpty ? "Unavailable" : monitor.snapshot.network.localIPv6, icon: "network.badge.shield.half.filled", fontSize: sizeBody)
                        }
                        Divider().opacity(0.05)
                        HStack(spacing: 12) {
                            NetworkMetricBox(label: "DOWNLOAD", value: monitor.snapshot.network.downKBps, history: monitor.snapshot.network.downHistory, icon: "arrow.down", color: .blue, fontSize: sizeBody)
                            NetworkMetricBox(label: "UPLOAD", value: monitor.snapshot.network.upKBps, history: monitor.snapshot.network.upHistory, icon: "arrow.up", color: .green, fontSize: sizeBody)
                        }
                    }
                }
                
                // 5. Storage - INDEPENDENT ROW
                BentoCard(title: "STORAGE", icon: "internaldrive.fill", color: .cyan) {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.0f%% Used", (monitor.snapshot.storage.usedGB / (monitor.snapshot.storage.totalGB > 0 ? monitor.snapshot.storage.totalGB : 1)) * 100))
                                .font(.system(size: sizeMetric, weight: .bold, design: .rounded))
                            CapsuleProgress(progress: monitor.snapshot.storage.totalGB > 0 ? monitor.snapshot.storage.usedGB / monitor.snapshot.storage.totalGB : 0, color: .cyan)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(Int(monitor.snapshot.storage.totalGB - monitor.snapshot.storage.usedGB)) GB")
                                .font(.system(size: sizeMetric, weight: .bold, design: .rounded))
                            Text("FREE").font(.system(size: sizeCaption, weight: .bold)).foregroundColor(.secondary)
                        }
                    }
                }
                 
                // 6. Devices - INDEPENDENT ROW
                BentoCard(title: "CONNECTED DEVICES", icon: "keyboard", color: .secondary) {
                    VStack(spacing: 8) {
                        if monitor.snapshot.bluetoothDevices.isEmpty {
                            Text("No external devices connected").font(.system(size: sizeBody, weight: .bold)).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(monitor.snapshot.bluetoothDevices) { device in
                                HStack {
                                    Image(systemName: DeviceIconResolver.iconName(for: device.name)).font(.system(size: 10)).foregroundColor(.secondary).frame(width: 15)
                                    Text(device.name).font(.system(size: sizeBody, weight: .bold)).lineLimit(1)
                                    Spacer()
                                    Text("\(device.battery)%").font(.system(size: sizeBody, weight: .bold, design: .monospaced))
                                        .foregroundColor(device.battery < 20 ? .red : .primary)
                                    
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.primary.opacity(0.05)).frame(width: 30, height: 4)
                                        Capsule().fill(device.battery < 20 ? Color.red : Color.green)
                                            .frame(width: 30 * CGFloat(Double(device.battery)/100.0), height: 4)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 7. Top Processes Row
                BentoCard(title: "TOP PROCESSES", icon: "list.bullet.indent", color: .secondary, bodySpacing: monitor.isProcessesExpanded || isProcessBodyMounted ? 6 : 1, trailing: {
                    Button(action: {
                        monitor.isProcessesExpanded.toggle()
                    }) {
                        ZStack {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .rotationEffect(.degrees(monitor.isProcessesExpanded ? 180 : 0))
                                .animation(.easeInOut(duration: 0.16), value: monitor.isProcessesExpanded)
                        }
                        .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }) {
                    if isProcessBodyMounted || monitor.isProcessesExpanded {
                        ZStack(alignment: .top) {
                            ProcessListContent(processes: Array(monitor.snapshot.topProcesses.prefix(10)), fontSize: sizeBody)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(key: ProcessListHeightPreferenceKey.self, value: geo.size.height)
                                    }
                                )
                                .hidden()

                            if isProcessBodyMounted {
                                ProcessListContent(processes: Array(monitor.snapshot.topProcesses.prefix(10)), fontSize: sizeBody)
                                    .opacity(processRevealProgress)
                                    .mask(alignment: .top) {
                                        Rectangle()
                                            .frame(height: max(1, processListHeight * processRevealProgress))
                                    }
                            }
                        }
                        .frame(height: isProcessBodyMounted ? processListHeight : 0, alignment: .top)
                        .clipped()
                        .onPreferenceChange(ProcessListHeightPreferenceKey.self) { height in
                            processListHeight = height
                        }
                    }
                }
                
                FooterButtons()
            }
            .padding([.horizontal, .bottom], 16)
        }
        .frame(width: 328)
        .fixedSize(horizontal: false, vertical: true)
        .background(VisualEffectView(material: .popover, blendingMode: .withinWindow))
        .onAppear {
            syncProcessAnimationState(animated: false)
        }
        .onChange(of: monitor.isProcessesExpanded) { _, _ in
            syncProcessAnimationState(animated: true)
        }
    }

    private func syncProcessAnimationState(animated: Bool) {
        let duration = 0.16
        processAnimationVersion += 1
        let animationVersion = processAnimationVersion

        if monitor.isProcessesExpanded {
            isProcessBodyMounted = true
            let reveal = {
                processRevealProgress = 1
            }

            if animated {
                processRevealProgress = 0
                DispatchQueue.main.async {
                    guard animationVersion == processAnimationVersion, monitor.isProcessesExpanded else { return }
                    withAnimation(.easeOut(duration: duration)) {
                        reveal()
                    }
                }
            } else {
                reveal()
            }
        } else {
            let hide = {
                processRevealProgress = 0
            }

            if animated {
                hide()
                isProcessBodyMounted = false
            } else {
                hide()
                isProcessBodyMounted = false
            }
        }
    }
}

// MARK: - Components

private struct ProcessListHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ProcessListContent: View {
    let processes: [ProcessStat]
    let fontSize: CGFloat

    var body: some View {
        VStack(spacing: 5) {
            ForEach(processes) { proc in
                HStack {
                    Text(proc.name).font(.system(size: fontSize, weight: .bold)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) {
                        Text(String(format: "%.1f%%", proc.cpu))
                        Text(String(format: "%.1f%%", proc.memory)).foregroundColor(.secondary)
                    }.font(.system(size: fontSize, weight: .bold, design: .monospaced))
                }
            }
        }
    }
}

struct NetworkInfoRow: View {
    let label: String; let value: String; let icon: String; let fontSize: CGFloat
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: fontSize-1)).foregroundColor(.secondary).frame(width: 12)
            Text(label).font(.system(size: fontSize-2, weight: .black)).foregroundColor(.secondary).frame(width: 40, alignment: .leading)
            Text(value).font(.system(size: fontSize, weight: .bold, design: .monospaced)).lineLimit(1).foregroundColor(.primary)
            Spacer()
        }
    }
}

struct NetworkMetricBox: View {
    let label: String; let value: Double; let history: [Double]; let icon: String; let color: Color; let fontSize: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: fontSize-1, weight: .black))
                Text(label).font(.system(size: fontSize-1, weight: .black)).foregroundColor(.secondary)
            }
            Text(formatValue(value)).font(.system(size: fontSize+5, weight: .bold, design: .monospaced))
            Sparkline(data: history, color: color).frame(height: 12).opacity(0.6)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    func formatValue(_ kbps: Double) -> String {
        DisplayFormatters.networkSpeed(kbps)
    }
}

struct PingIndicator: View {
    let latency: Double
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(statusColor).frame(width: 6, height: 6)
            Text(latency < 0 ? "Offline" : String(format: "%.0fms", latency))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
    var statusColor: Color {
        if latency < 0 { return .red }
        if latency < 50 { return .green }
        if latency < 150 { return .yellow }
        return .red
    }
}

struct FooterButtons: View {
    var body: some View {
        HStack(spacing: 10) {
            FooterButton(title: "Monitor", icon: "chart.bar.xaxis", action: { NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")) })
            FooterButton(title: "Quit", icon: "power", color: .red, action: { NSApplication.shared.terminate(nil) })
        }.padding(.top, 2)
    }
}

struct BentoHeader: View {
    @ObservedObject var monitor: SystemMonitor
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(AppMetadata.displayName).font(.system(size: 16, weight: .black, design: .rounded))
                Text("\(monitor.snapshot.modelName)  ·  Up \(formattedUptime)").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary)
            }
            Spacer()
            Text(monitor.snapshot.version).font(.system(size: 8, weight: .black)).padding(.horizontal, 6).padding(.vertical, 3).background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(5)
        }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)
    }

    private var formattedUptime: String {
        let interval = Int(ProcessInfo.processInfo.systemUptime)
        let days = interval / 86400
        let hours = (interval % 86400) / 3600
        let minutes = (interval % 3600) / 60

        if days > 0 {
            return String(format: "%dd %02dh", days, hours)
        }
        return String(format: "%dh %02dm", hours, minutes)
    }
}

struct BentoCard<Content: View, Trailing: View>: View {
    let title: String; let icon: String; let color: Color; let bodySpacing: CGFloat; let content: Content; let trailing: Trailing
    init(title: String, icon: String, color: Color, bodySpacing: CGFloat = 6, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.color = color; self.bodySpacing = bodySpacing; self.trailing = trailing(); self.content = content()
    }
    init(title: String, icon: String, color: Color, bodySpacing: CGFloat = 6, @ViewBuilder content: () -> Content) where Trailing == EmptyView {
        self.init(title: title, icon: icon, color: color, bodySpacing: bodySpacing, trailing: { EmptyView() }, content: content)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: bodySpacing) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 9))
                Text(title).font(.system(size: 9, weight: .black))
                Spacer()
                trailing
            }.foregroundColor(color.opacity(0.8))
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

struct CircularProgress: View {
    let progress: Double; let color: Color; let size: CGFloat
    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.1), lineWidth: 4)
            Circle().trim(from: 0, to: CGFloat(min(max(progress, 0.001), 1))).stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90))
        }.frame(width: size, height: size)
    }
}

struct CapsuleProgress: View {
    let progress: Double; let color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.1))
                Capsule().fill(color).frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
            }
        }.frame(height: 4)
    }
}

struct FooterButton: View {
    let title: String; let icon: String; var color: Color = .primary; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold))
                Text(title).font(.system(size: 11, weight: .bold))
            }.frame(maxWidth: .infinity).padding(.vertical, 8).background(Color.primary.opacity(0.05)).foregroundColor(color.opacity(0.8)).cornerRadius(10)
        }.buttonStyle(.plain)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material; let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView(); view.material = material; view.blendingMode = blendingMode; view.state = .active; return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct Sparkline: View {
    let data: [Double]; let color: Color
    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard data.count > 1 else { return }
                let step = geo.size.width / CGFloat(data.count - 1)
                let height = geo.size.height
                let points = data.enumerated().map { (index, value) -> CGPoint in
                    let x = CGFloat(index) * step
                    let maxVal = data.max() ?? 1.0
                    let normalized = maxVal > 0 ? (CGFloat(value) / CGFloat(maxVal)) : 0
                    let y = height - (normalized * height)
                    return CGPoint(x: x, y: y)
                }
                path.move(to: points[0])
                for i in 1..<points.count { path.addLine(to: points[i]) }
            }.stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}
