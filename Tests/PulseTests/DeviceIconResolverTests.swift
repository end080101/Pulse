import XCTest
@testable import Pulse

final class DeviceIconResolverTests: XCTestCase {
    func testResolvesAirPodsIcon() {
        XCTAssertEqual(DeviceIconResolver.iconName(for: "AirPods Pro"), "headphones")
    }

    func testResolvesTrackpadIcon() {
        XCTAssertEqual(DeviceIconResolver.iconName(for: "Magic Trackpad"), "magictrackpad.fill")
    }

    func testFallsBackToBluetoothIcon() {
        XCTAssertEqual(DeviceIconResolver.iconName(for: "Unknown Peripheral"), "bluetooth")
    }
}
