import Foundation

public final class SystemMonitor: ObservableObject {
    @Published var snapshot: SystemSnapshot
    @Published public var isProcessesExpanded: Bool = false {
        didSet {
            if isProcessesExpanded,
               snapshot.topProcesses.isEmpty || Date().timeIntervalSince(lastProcessRefreshAt) > 20 {
                refreshProcessMetrics(force: true)
            }
        }
    }
    @Published public var logoType: String = "gif"

    private let cpuMonitor = CPUMonitor()
    private let networkMonitor = NetworkMonitor()
    private let helperService = HelperStreamService()

    private var fastTimer: Timer?
    private var slowTimer: Timer?
    private var processTimer: Timer?
    private var lastFastRefreshAt = Date()
    private var lastProcessRefreshAt = Date.distantPast
    private var isRefreshingProcesses = false

    public init() {
        self.snapshot = SystemSnapshot(
            modelName: MachineInfo.modelName(),
            version: AppMetadata.versionString
        )

        helperService.onPayload = { [weak self] payload in
            DispatchQueue.main.async {
                self?.apply(payload: payload)
            }
        }

        startMonitoring()
        refreshPublicIP()
        helperService.start()
    }

    deinit {
        fastTimer?.invalidate()
        slowTimer?.invalidate()
        processTimer?.invalidate()
        helperService.stop()
    }

    public func startMonitoring() {
        refreshFastMetrics()
        refreshSlowMetrics()

        fastTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshFastMetrics()
        }

        slowTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.refreshSlowMetrics()
        }

        refreshProcessMetrics(force: true)

        processTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.refreshProcessMetrics(force: true)
        }
    }

    private func refreshFastMetrics() {
        let now = Date()
        let interval = now.timeIntervalSince(lastFastRefreshAt)
        lastFastRefreshAt = now

        if let cpu = cpuMonitor.refresh(history: snapshot.cpu.history) {
            snapshot.cpu.usage = cpu.usage
            snapshot.cpu.history = cpu.history
        }

        if let memory = MemoryMonitor.refresh() {
            snapshot.memory = memory
        }

        snapshot.gpu = GPUMonitor.refresh()

        if let network = networkMonitor.refreshUsage(current: snapshot.network, interval: interval) {
            snapshot.network = network
        }
    }

    private func refreshSlowMetrics() {
        if let storage = StorageMonitor.refresh() {
            snapshot.storage = storage
        }

        snapshot.battery = BatteryMonitor.refresh()
        snapshot.bluetoothDevices = BluetoothMonitor.refresh()
        snapshot.network = networkMonitor.refreshWiFiName(current: snapshot.network)

        networkMonitor.refreshPing { [weak self] latency in
            DispatchQueue.main.async {
                self?.snapshot.network.pingLatency = latency
            }
        }

        refreshProcessMetrics(force: true)
    }

    private func refreshProcessMetrics(force: Bool) {
        guard (force || isProcessesExpanded), !isRefreshingProcesses else { return }
        isRefreshingProcesses = true

        ProcessMonitor.refresh { [weak self] processes in
            DispatchQueue.main.async {
                guard let self else { return }
                self.snapshot.topProcesses = processes
                self.lastProcessRefreshAt = Date()
                self.isRefreshingProcesses = false
            }
        }
    }

    private func refreshPublicIP() {
        networkMonitor.fetchPublicIP { [weak self] ip in
            DispatchQueue.main.async {
                self?.snapshot.network.publicIP = ip
            }
        }
    }

    private func apply(payload: HelperPayload) {
        if let temperature = payload.temperature {
            snapshot.cpu.temperature = temperature
        }

        if let milliwatts = payload.packageMilliwatts, milliwatts > 0 {
            snapshot.power.usageWatts = milliwatts / 1000.0
            snapshot.power.isMeasured = true
        } else if !snapshot.power.isMeasured {
            snapshot.power.usageWatts = 4.5 + ((snapshot.cpu.usage / 100.0) * 12.0)
        }

        if let wifiSSID = payload.wifiSSID, !wifiSSID.isEmpty {
            snapshot.network.wifiSSID = wifiSSID
        }
    }

}
