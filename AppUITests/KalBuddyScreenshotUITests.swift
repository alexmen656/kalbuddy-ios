//
//  KalBuddyScreenshotUITests.swift
//  AppUITests
//
//  Automated App Store screenshots for the KalBuddy Capacitor app.
//
//  KalBuddy renders inside a WKWebView, so instead of tapping native controls we
//  drive it through launch-argument flags that the web app reads via Capacitor
//  Preferences (`-CapacitorStorage.<key> <value>` lands in UserDefaults):
//
//    ui_test_mode        "1"      seed demo data, force premium, skip onboarding
//    ui_test_start_route "/path"  navigate straight to the screen to capture
//
//  Each test launches fresh at one route and captures one screenshot — no
//  in-web-view navigation, which keeps the run fast and stable across languages.
//

import XCTest

@MainActor
final class KalBuddyScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app straight onto `route` with demo data seeded.
    /// `settle` gives the web view time to render (longer for network-bound
    /// screens such as the paywall, which loads RevenueCat offerings).
    private func launch(route: String, settle: TimeInterval = 3.0) -> XCUIApplication {
        let app = XCUIApplication()
        setupScreenshots(app) // forwards -AppleLanguages / -AppleLocale
        app.launchArguments += [
            "-CapacitorStorage.ui_test_mode", "1",
            "-CapacitorStorage.ui_test_start_route", route,
        ]
        app.launch()

        XCTAssertTrue(
            app.webViews.firstMatch.waitForExistence(timeout: 30),
            "Capacitor web view never appeared"
        )
        Thread.sleep(forTimeInterval: settle)
        return app
    }

    func testScreenshot00_home() throws {
        _ = launch(route: "/")
        takeScreenshot("testScreenshot00_home")
    }

    func testScreenshot01_analytics() throws {
        _ = launch(route: "/analytics", settle: 4.0)
        takeScreenshot("testScreenshot01_analytics")
    }

    func testScreenshot02_streak() throws {
        _ = launch(route: "/streak")
        takeScreenshot("testScreenshot02_streak")
    }

    func testScreenshot03_foodDatabase() throws {
        _ = launch(route: "/food-database", settle: 4.0)
        takeScreenshot("testScreenshot03_foodDatabase")
    }

    func testScreenshot04_upgrade() throws {
        // The paywall fetches RevenueCat offerings over the network — give it longer.
        _ = launch(route: "/upgrade", settle: 6.0)
        takeScreenshot("testScreenshot04_upgrade")
    }
}
