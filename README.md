# Pulse

Pulse is an open-source macOS menu bar system monitor built with SwiftUI.

It focuses on a compact menu bar experience, a polished popover dashboard, and a codebase that stays intentionally selective instead of trying to expose every possible system metric.

## Features

- CPU usage, hotspot temperature, and history
- RAM usage
- GPU utilization
- Package power via `powermetrics` when available, with estimate fallback
- Disk capacity usage
- Network throughput, SSID, public IP, IPv4, and ping
- Battery status on supported Macs
- Bluetooth device battery levels
- Top process list

## Design goals

- Keep the current Pulse UI direction intact
- Evolve the codebase into a maintainable open-source project
- Separate monitoring logic, state models, and UI concerns
- Keep the dashboard compact and avoid turning it into an overloaded clone of larger tools

## Project structure

```text
Sources/Pulse/
  PulseApp.swift
  SystemMonitor.swift
  Models/
  Monitoring/
  Support/
  Resources/
Tests/PulseTests/
```

## Requirements

- macOS 14+
- Xcode 15+ or Swift 5.9+

## Requirements

- macOS 14+
- Xcode 15+ or Swift 5.9+

## Build

```bash
swift build
```

## Run tests

```bash
swift test
```

## Package app bundle

```bash
./package.sh
```

This produces `Pulse.app` and `Pulse.dmg`.

## Notes on system access

Pulse reads a mix of public system APIs, command line tools, and helper-provided data. Some metrics may require extra permissions or may vary across macOS versions and hardware generations.

- Package power comes from `powermetrics` via a helper when available.
- The current helper flow is transitional and not yet the final open-source-friendly privileged helper design.
- Bluetooth device coverage is intentionally conservative and may not include every connected accessory.

## Roadmap

- Add a proper preferences window
- Replace the current helper installation path with a more standard macOS approach
- Add module-level configuration and toggles
- Expand test coverage for monitoring and presentation logic
- Improve release automation and contributor docs

## Release status

- Current version: `1.0.0`
- Public app name: `Pulse`
- Swift package and executable product name: `Pulse`

## Contributing

See `CONTRIBUTING.md`.

## License

MIT. See `LICENSE`.
