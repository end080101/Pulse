import XCTest
@testable import Pulse

final class DisplayFormattersTests: XCTestCase {
    func testFormatsKilobytesPerSecond() {
        XCTAssertEqual(DisplayFormatters.networkSpeed(512), "512 KB/s")
    }

    func testFormatsMegabytesPerSecond() {
        XCTAssertEqual(DisplayFormatters.networkSpeed(1536), "1.5 MB/s")
    }

    func testFormatsWifiFallbackLabel() {
        XCTAssertEqual(DisplayFormatters.wifiLabel("No WiFi"), "No WiFi / Wired")
        XCTAssertEqual(DisplayFormatters.wifiLabel("OfficeNet"), "OfficeNet")
    }
}
