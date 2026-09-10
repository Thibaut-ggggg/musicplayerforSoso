import XCTest
@testable import MacPod

final class WindowPositionTests: XCTestCase {
    func testPositionSurvivesANewDefaultsInstance() {
        let suite = "MacPodTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertNil(WindowPosition.load(from: defaults))
        let origin = CGPoint(x: -900, y: 125)
        WindowPosition.save(origin, to: defaults)
        XCTAssertEqual(WindowPosition.load(from: UserDefaults(suiteName: suite)!), origin)
    }

    func testMalformedPositionFallsBack() {
        let suite = "MacPodTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["x": "broken", "y": 50], forKey: "windowPosition")
        XCTAssertNil(WindowPosition.load(from: defaults))
        defaults.set(["x": 50], forKey: "windowPosition")
        XCTAssertNil(WindowPosition.load(from: defaults))
    }

    func testPositionOnSecondaryDisplayIsPreserved() {
        let screens = [CGRect(x: 0, y: 0, width: 1440, height: 900),
                       CGRect(x: -1920, y: 0, width: 1920, height: 1080)]
        let origin = CGPoint(x: -900, y: 125)
        XCTAssertEqual(WindowPosition.constrained(origin, size: CGSize(width: 163, height: 152),
                                                   visibleFrames: screens), origin)
    }

    func testDisconnectedDisplayFallsBackOnscreen() {
        XCTAssertEqual(WindowPosition.constrained(
            CGPoint(x: -900, y: 1200), size: CGSize(width: 163, height: 152),
            visibleFrames: [CGRect(x: 0, y: 24, width: 1440, height: 850)]
        ), CGPoint(x: 0, y: 722))
    }

    func testLargerShellFitsWithinVisibleFrame() {
        XCTAssertEqual(WindowPosition.constrained(
            CGPoint(x: 1300, y: 700), size: CGSize(width: 180, height: 390),
            visibleFrames: [CGRect(x: 0, y: 24, width: 1440, height: 850)]
        ), CGPoint(x: 1260, y: 484))
    }
}
