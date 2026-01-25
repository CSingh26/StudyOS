import XCTest

final class StudyOSUITests: XCTestCase {
    func testOnboardingDemoFlow() {
        let app = launchApp(reset: true)
        completeOnboardingIfNeeded(app)
        XCTAssertTrue(app.tabBars.buttons["Today"].exists)
        let root = app.otherElements["app-shell-root"]
        XCTAssertTrue(root.waitForExistence(timeout: 5))
        XCTAssertTrue(root.isHittable)
        let window = app.windows.firstMatch
        XCTAssertEqual(root.frame.size.width, window.frame.size.width, accuracy: 1)
        XCTAssertEqual(root.frame.size.height, window.frame.size.height, accuracy: 1)
    }

    func testTodayStartFocusSession() {
        let app = launchApp(reset: true)
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Today"].tap()
        let startButton = app.buttons["Start"].firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        XCTAssertTrue(app.staticTexts["Focus Session"].waitForExistence(timeout: 5))
        app.buttons["Finish"].tap()
    }

    func testAssignmentDetailOpens() {
        let app = launchApp(reset: true)
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Assignments"].tap()
        let firstCell = app.tables.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()
        XCTAssertTrue(app.navigationBars["Assignment"].waitForExistence(timeout: 5))
    }

    private func launchApp(reset: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        if reset {
            app.launchArguments.append("UITEST_RESET")
        }
        app.launch()
        return app
    }

    private func completeOnboardingIfNeeded(_ app: XCUIApplication) {
        let nextButton = app.buttons["Next"]
        if nextButton.waitForExistence(timeout: 2) {
            nextButton.tap()
            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
            }
            let demoButton = app.buttons["Demo"]
            if demoButton.waitForExistence(timeout: 2) {
                demoButton.tap()
            }
            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
            }
            let continueButton = app.buttons["Continue"]
            if continueButton.waitForExistence(timeout: 2) {
                continueButton.tap()
            }
            let enterButton = app.buttons["Enter StudyOS"]
            if enterButton.waitForExistence(timeout: 2) {
                enterButton.tap()
            }
        }
    }
}
