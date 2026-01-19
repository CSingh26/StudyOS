public protocol LLMProvider: Sendable {
    func summarize(text: String) async throws -> String
}
