import Foundation
import OSLog

/// Centralized logging system for the Scribe app
/// Replaces all print() statements with proper OSLog integration
public final class ScribeLogger {
    // MARK: - Singleton
    public static let shared = ScribeLogger()
    
    // MARK: - Loggers by Category
    private let bleLogger = Logger(subsystem: "com.scribe.app", category: "BLE")
    private let audioLogger = Logger(subsystem: "com.scribe.app", category: "Audio")
    private let mlLogger = Logger(subsystem: "com.scribe.app", category: "ML")
    private let uiLogger = Logger(subsystem: "com.scribe.app", category: "UI")
    private let pipelineLogger = Logger(subsystem: "com.scribe.app", category: "Pipeline")
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public API
    
    public func debug(_ message: String, category: LogCategory = .general) {
        log(message, level: .debug, category: category)
    }
    
    public func info(_ message: String, category: LogCategory = .general) {
        log(message, level: .info, category: category)
    }
    
    public func warning(_ message: String, category: LogCategory = .general) {
        log(message, level: .default, category: category)
    }
    
    public func error(_ message: String, category: LogCategory = .general) {
        log(message, level: .error, category: category)
    }
    
    public func fault(_ message: String, category: LogCategory = .general) {
        log(message, level: .fault, category: category)
    }
    
    // MARK: - Private
    
    private func log(_ message: String, level: OSLogType, category: LogCategory) {
        let logger = loggerFor(category)
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .default:
            logger.log("\(message)")
        case .error:
            logger.error("\(message)")
        case .fault:
            logger.fault("\(message)")
        default:
            logger.log("\(message)")
        }
    }
    
    private func loggerFor(_ category: LogCategory) -> Logger {
        switch category {
        case .ble:
            return bleLogger
        case .audio:
            return audioLogger
        case .ml:
            return mlLogger
        case .ui:
            return uiLogger
        case .pipeline:
            return pipelineLogger
        case .general:
            return Logger(subsystem: "com.scribe.app", category: "General")
        }
    }
}

// MARK: - Log Category
public enum LogCategory {
    case ble
    case audio
    case ml
    case ui
    case pipeline
    case general
}

// MARK: - Convenience Static Methods
extension ScribeLogger {
    public static func debug(_ message: String, category: LogCategory = .general) {
        shared.debug(message, category: category)
    }
    
    public static func info(_ message: String, category: LogCategory = .general) {
        shared.info(message, category: category)
    }
    
    public static func warning(_ message: String, category: LogCategory = .general) {
        shared.warning(message, category: category)
    }
    
    public static func error(_ message: String, category: LogCategory = .general) {
        shared.error(message, category: category)
    }
    
    public static func fault(_ message: String, category: LogCategory = .general) {
        shared.fault(message, category: category)
    }
}
