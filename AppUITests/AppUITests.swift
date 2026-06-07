//
//  AppUITests.swift
//  AppUITests
//
//  KalBuddy screenshot pipeline - see config.json for device/language config.
//  Demo data is seeded via CapacitorStorage.ui_test_mode.
//

import XCTest

@MainActor
final class AppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupScreenshots(app)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func launch(route: String, settle: TimeInterval = 3.0) {
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
    }

    func testScreenshot00_home() throws {
        launch(route: "/")
        takeScreenshot("testScreenshot00_home")
    }

    func testScreenshot01_analytics() throws {
        launch(route: "/analytics", settle: 4.0)
        takeScreenshot("testScreenshot01_analytics")
    }

    func testScreenshot02_streak() throws {
        launch(route: "/streak")
        takeScreenshot("testScreenshot02_streak")
    }

    func testScreenshot03_foodDatabase() throws {
        launch(route: "/food-database", settle: 4.0)
        takeScreenshot("testScreenshot03_foodDatabase")
    }

    func testScreenshot04_upgrade() throws {
        launch(route: "/upgrade", settle: 6.0)
        takeScreenshot("testScreenshot04_upgrade")
    }
}
