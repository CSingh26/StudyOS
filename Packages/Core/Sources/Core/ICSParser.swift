import Foundation

public struct ICSEvent: Sendable, Codable, Equatable {
    public var uid: String?
    public var summary: String
    public var description: String
    public var location: String
    public var startDate: Date
    public var endDate: Date

    public init(
        uid: String?,
        summary: String,
        description: String,
        location: String,
        startDate: Date,
        endDate: Date
    ) {
        self.uid = uid
        self.summary = summary
        self.description = description
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
    }
}

public enum ICSParserError: LocalizedError {
    case invalidEncoding

    public var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "ICS file encoding is not supported."
        }
    }
}

public enum ICSParser {
    public static func parse(_ data: Data) throws -> [ICSEvent] {
        let content = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
        guard let content else {
            throw ICSParserError.invalidEncoding
        }

        let unfoldedLines = unfoldLines(content)
        var events: [ICSEvent] = []
        var current: [String: (value: String, params: [String: String])] = [:]
        var inEvent = false

        for line in unfoldedLines {
            if line == "BEGIN:VEVENT" {
                inEvent = true
                current = [:]
                continue
            }
            if line == "END:VEVENT" {
                if let event = makeEvent(from: current) {
                    events.append(event)
                }
                inEvent = false
                continue
            }
            guard inEvent else { continue }

            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let nameAndParams = parts[0].split(separator: ";")
            let name = nameAndParams.first?.uppercased() ?? ""
            var params: [String: String] = [:]
            if nameAndParams.count > 1 {
                for param in nameAndParams.dropFirst() {
                    let kv = param.split(separator: "=", maxSplits: 1)
                    if kv.count == 2 {
                        params[String(kv[0]).uppercased()] = String(kv[1])
                    }
                }
            }
            let value = String(parts[1])
            current[name] = (value: value, params: params)
        }

        return events
    }

    private static func makeEvent(from values: [String: (value: String, params: [String: String])]) -> ICSEvent? {
        guard let startEntry = values["DTSTART"] else { return nil }
        let endEntry = values["DTEND"]
        let uid = values["UID"]?.value
        let summary = unescape(values["SUMMARY"]?.value ?? "Untitled")
        let description = unescape(values["DESCRIPTION"]?.value ?? "")
        let location = unescape(values["LOCATION"]?.value ?? "")

        let startDate = parseDate(value: startEntry.value, tzid: startEntry.params["TZID"]) ?? Date()
        let endDate = parseDate(value: endEntry?.value ?? "", tzid: endEntry?.params["TZID"]) ?? startDate

        return ICSEvent(
            uid: uid,
            summary: summary,
            description: description,
            location: location,
            startDate: startDate,
            endDate: endDate
        )
    }

    private static func unfoldLines(_ content: String) -> [String] {
        var result: [String] = []
        let lines = content.split(whereSeparator: \.isNewline)
        for raw in lines {
            let line = String(raw)
            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                if let last = result.last {
                    result[result.count - 1] = last + line.trimmingCharacters(in: .whitespaces)
                }
            } else {
                result.append(line.trimmingCharacters(in: .whitespaces))
            }
        }
        return result
    }

    private static func parseDate(value: String, tzid: String?) -> Date? {
        guard !value.isEmpty else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespaces)

        if trimmed.count == 8 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            formatter.timeZone = timeZone(from: tzid)
            return formatter.date(from: trimmed)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        if trimmed.hasSuffix("Z") {
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: String(trimmed.dropLast()))
        }
        formatter.timeZone = timeZone(from: tzid)
        return formatter.date(from: trimmed)
    }

    private static func timeZone(from tzid: String?) -> TimeZone {
        guard let tzid, let zone = TimeZone(identifier: tzid) else {
            return TimeZone.current
        }
        return zone
    }

    private static func unescape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
    }
}
