import XCTest
import Core

final class ICSParserTests: XCTestCase {
    func testParsesBasicEvent() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        UID:abc123
        SUMMARY:Midterm Review
        DTSTART:20240220T120000Z
        DTEND:20240220T133000Z
        DESCRIPTION:Line1\\nLine2
        LOCATION:Library
        END:VEVENT
        END:VCALENDAR
        """
        let data = Data(ics.utf8)
        let events = try ICSParser.parse(data)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.uid, "abc123")
        XCTAssertEqual(events.first?.summary, "Midterm Review")
        XCTAssertEqual(events.first?.location, "Library")
        XCTAssertTrue(events.first?.description.contains("Line1") ?? false)
    }

    func testParsesTimeZoneEvent() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        UID:tz-1
        SUMMARY:Office Hours
        DTSTART;TZID=America/New_York:20240220T090000
        DTEND;TZID=America/New_York:20240220T100000
        END:VEVENT
        END:VCALENDAR
        """
        let data = Data(ics.utf8)
        let events = try ICSParser.parse(data)
        let event = try XCTUnwrap(events.first)
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: event.startDate)
        XCTAssertEqual(hour, 9)
    }

    func testSkipsInvalidEvents() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Missing Dates
        END:VEVENT
        END:VCALENDAR
        """
        let data = Data(ics.utf8)
        let events = try ICSParser.parse(data)
        XCTAssertTrue(events.isEmpty)
    }
}
