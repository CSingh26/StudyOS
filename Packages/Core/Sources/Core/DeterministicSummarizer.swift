import Foundation
import NaturalLanguage

public struct AssignmentSummary: Sendable {
    public var whatToDo: [String]
    public var deliverables: [String]
    public var constraints: [String]
    public var links: [String]
    public var keywords: [String]

    public init(
        whatToDo: [String] = [],
        deliverables: [String] = [],
        constraints: [String] = [],
        links: [String] = [],
        keywords: [String] = []
    ) {
        self.whatToDo = whatToDo
        self.deliverables = deliverables
        self.constraints = constraints
        self.links = links
        self.keywords = keywords
    }
}

public enum DeterministicSummarizer {
    public static func summarize(text: String) -> AssignmentSummary {
        let sentences = splitSentences(text)
        var summary = AssignmentSummary()
        summary.links = extractLinks(text)
        summary.keywords = extractKeywords(text)

        for sentence in sentences {
            let lower = sentence.lowercased()
            if containsDeliverableCue(lower) {
                summary.deliverables.append(sentence)
            } else if containsConstraintCue(lower) {
                summary.constraints.append(sentence)
            } else {
                summary.whatToDo.append(sentence)
            }
        }

        if let dueHint = extractDueHint(text) {
            summary.constraints.append(dueHint)
        }

        return summary
    }

    private static func splitSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }
        return sentences
    }

    private static func extractKeywords(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        let stopwords: Set<String> = [
            "the", "and", "or", "to", "of", "in", "a", "an", "for", "with", "on", "by", "is", "are",
            "be", "as", "at", "from", "this", "that", "it", "your", "you", "we", "our", "must"
        ]
        var counts: [String: Int] = [:]
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = text[range].lowercased()
            guard token.count > 2, !stopwords.contains(token) else { return true }
            counts[token, default: 0] += 1
            return true
        }
        return counts.sorted { $0.value > $1.value }.prefix(8).map { $0.key }
    }

    private static func extractLinks(_ text: String) -> [String] {
        let pattern = "https?://[^\\s]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }

    private static func extractDueHint(_ text: String) -> String? {
        let pattern = "due\\s+(on|by)\\s+([A-Za-z0-9 ,:-]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func containsDeliverableCue(_ sentence: String) -> Bool {
        sentence.contains("submit") || sentence.contains("turn in") || sentence.contains("deliver")
    }

    private static func containsConstraintCue(_ sentence: String) -> Bool {
        sentence.contains("must") || sentence.contains("required") || sentence.contains("format") || sentence.contains("include")
    }
}
