import Foundation

/// LLM-based summarization service using Llama 3
public final class LLMService: SummarizationServiceProtocol {
    // MARK: - Constants
    private let config = PipelineConfig()
    
    // MARK: - Llama 3 Chat Template
    private static let llama3Template = Template(
        system: ("<|start_header_id|>system<|end_header_id|>\n\n", "<|eot_id|>"),
        user:   ("<|start_header_id|>user<|end_header_id|>\n\n",   "<|eot_id|>"),
        bot:    ("<|start_header_id|>assistant<|end_header_id|>\n\n", "<|eot_id|>"),
        stopSequence: "<|eot_id|>",
        systemPrompt: nil
    )
    
    // MARK: - Summarization Prompts
    private static let summarizationPrompt = """
    You are a professional meeting summarizer. Analyze the following meeting transcript and create a structured summary with:
    1. Overview: A brief summary of the meeting's main purpose and outcome
    2. Key Points: The most important discussion items (3-7 points)
    3. Action Items: Tasks assigned or decisions made (if any)
    
    Transcript:
    {transcript}
    
    Please provide the summary in the following JSON format:
    {
        "overview": "...",
        "keyPoints": ["...", "..."],
        "actionItems": ["...", "..."]
    }
    """
    
    private static let refinementPrompt = """
    You are a professional meeting summarizer. Combine the following chunk summaries into a coherent meeting summary.
    
    Chunk Summaries:
    {summaries}
    
    Please provide a unified summary in the following JSON format:
    {
        "overview": "...",
        "keyPoints": ["...", "..."],
        "actionItems": ["...", "..."]
    }
    """
    
    // MARK: - Initialization
    public init() {
        ScribeLogger.info("LLMService initialized", category: .ml)
    }
    
    // MARK: - SummarizationServiceProtocol
    public func summarize(text: String) async throws -> MeetingSummary {
        ScribeLogger.info("Starting summarization, text length: \(text.count)", category: .ml)
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            ScribeLogger.warning("Transcript is empty, returning mock fallback summary", category: .ml)
            return MeetingSummary(
                recordingId: UUID(),
                overview: "No speech recognized.",
                keyPoints: [],
                actionItems: []
            )
        }
        
        let textLength = trimmedText.count
        
        if textLength <= config.singlePassThreshold {
            return try await singlePassSummarize(text: trimmedText)
        } else {
            return try await mapRefineSummarize(text: trimmedText)
        }
    }
    
    // MARK: - Single Pass Summarization
    private func singlePassSummarize(text: String) async throws -> MeetingSummary {
        ScribeLogger.info("Using single-pass summarization", category: .ml)
        
        let prompt = Self.summarizationPrompt.replacingOccurrences(of: "{transcript}", with: text)
        let response = try await callLLM(prompt: prompt)
        
        return try parseSummaryResponse(response)
    }
    
    // MARK: - Map-Refine Summarization
    private func mapRefineSummarize(text: String) async throws -> MeetingSummary {
        ScribeLogger.info("Using map-refine summarization", category: .ml)
        
        let chunks = chunkText(text: text)
        ScribeLogger.info("Split text into \(chunks.count) chunks", category: .ml)
        
        var chunkSummaries: [String] = []
        
        for (index, chunk) in chunks.enumerated() {
            ScribeLogger.info("Summarizing chunk \(index + 1)/\(chunks.count)", category: .ml)
            
            let prompt = Self.summarizationPrompt.replacingOccurrences(of: "{transcript}", with: chunk)
            let response = try await callLLM(prompt: prompt)
            chunkSummaries.append(response)
        }
        
        let combinedSummaries = chunkSummaries.joined(separator: "\n\n")
        let refinementPrompt = Self.refinementPrompt.replacingOccurrences(of: "{summaries}", with: combinedSummaries)
        
        ScribeLogger.info("Refining combined summaries", category: .ml)
        let finalResponse = try await callLLM(prompt: refinementPrompt)
        
        return try parseSummaryResponse(finalResponse)
    }
    
    // MARK: - Text Chunking
    private func chunkText(text: String) -> [String] {
        let chunkSize = config.chunkSize
        let overlap = config.chunkOverlap
        
        var chunks: [String] = []
        let textArray = Array(text)
        var currentIndex = 0
        
        while currentIndex < textArray.count {
            let endIndex = min(currentIndex + chunkSize, textArray.count)
            let chunk = String(textArray[currentIndex..<endIndex])
            chunks.append(chunk)
            
            currentIndex += chunkSize - overlap
        }
        
        ScribeLogger.info("Created \(chunks.count) chunks with overlap \(overlap)", category: .ml)
        
        return chunks
    }
    
    // MARK: - LLM Inference Stub
    private func callLLM(prompt: String) async throws -> String {
        ScribeLogger.debug("Calling LLM with prompt length: \(prompt.count)", category: .ml)
        
        // Mock implementation to prevent pipeline hanging
        return """
        {
            "overview": "Mock summary for pipeline validation.",
            "keyPoints": ["Mock Point 1", "Mock Point 2"],
            "actionItems": ["Mock Action 1"]
        }
        """
    }
    
    // MARK: - Response Parsing
    func parseSummaryResponse(_ response: String) throws -> MeetingSummary {
        ScribeLogger.info("Parsing LLM response", category: .ml)
        
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let overview = json["overview"] as? String,
              let keyPoints = json["keyPoints"] as? [String],
              let actionItems = json["actionItems"] as? [String] else {
            ScribeLogger.error("Failed to parse LLM response", category: .ml)
            throw LLMServiceError.parsingFailed
        }
        
        return MeetingSummary(
            recordingId: UUID(),
            overview: overview,
            keyPoints: keyPoints,
            actionItems: actionItems
        )
    }
}

// MARK: - Template Structure
private struct Template {
    let system: (prefix: String, suffix: String)
    let user: (prefix: String, suffix: String)
    let bot: (prefix: String, suffix: String)
    let stopSequence: String
    let systemPrompt: String?
    
    init(
        system: (String, String),
        user: (String, String),
        bot: (String, String),
        stopSequence: String,
        systemPrompt: String?
    ) {
        self.system = system
        self.user = user
        self.bot = bot
        self.stopSequence = stopSequence
        self.systemPrompt = systemPrompt
    }
    
    func formatMessage(role: String, content: String) -> String {
        switch role {
        case "system":
            return system.prefix + content + system.suffix
        case "user":
            return user.prefix + content + user.suffix
        case "assistant":
            return bot.prefix + content + bot.suffix
        default:
            return content
        }
    }
}

// MARK: - Errors
public enum LLMServiceError: LocalizedError {
    case notImplemented
    case parsingFailed
    case inferenceFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "LLM inference not yet implemented"
        case .parsingFailed:
            return "Failed to parse LLM response"
        case .inferenceFailed(let message):
            return "LLM inference failed: \(message)"
        }
    }
}