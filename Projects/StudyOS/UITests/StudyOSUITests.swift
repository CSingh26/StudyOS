import XCTest

final class StudyOSUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["StudyOS"].exists)
    }
}
