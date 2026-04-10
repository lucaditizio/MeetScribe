import Foundation
import Combine

/// Orchestrates the recording lifecycle including source routing and BLE disconnect handling
/// Provides a high-level interface for managing recordings with automatic fallback
public final class RecordingOrchestrator {
    
    // MARK: - Publishers
    
    /// Publisher indicating whether recording is currently active
    public let isRecordingPublisher: AnyPublisher<Bool, Never>
    
    /// Publisher for the current recording source (nil when not recording)
    public let recordingSourcePublisher: AnyPublisher<RecordingSource?, Never>
    
    /// Publisher for recording errors
    public let recordingErrorPublisher: AnyPublisher<RecordingOrchestratorError, Never>
    
    /// Publisher indicating if a source switch occurred mid-recording
    public let didSwitchSourcePublisher: AnyPublisher<(from: RecordingSource, to: RecordingSource), Never>
    
    // MARK: - Private Properties
    
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    private let recordingSourceSubject = CurrentValueSubject<RecordingSource?, Never>(nil)
    private let recordingErrorSubject = PassthroughSubject<RecordingOrchestratorError, Never>()
    private let didSwitchSourceSubject = PassthroughSubject<(from: RecordingSource, to: RecordingSource), Never>()
    
    private let unifiedRecorder: UnifiedRecorder
    private let connectionManager: DeviceConnectionManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var connectionStateCancellable: AnyCancellable?
    private var activeRecordingTask: Task<Void, Never>?
    
    private var isTransitioningSource = false
    private var fallbackOnDisconnect = true
    
    // MARK: - Initialization
    
    /// Creates a recording orchestrator with the specified dependencies
    /// - Parameters:
    ///   - unifiedRecorder: The unified recorder for actual recording operations
    ///   - connectionManager: Manager for monitoring BLE connection state
    ///   - fallbackOnDisconnect: Whether to fallback to internal mic on BLE disconnect (default: true)
    public init(
        unifiedRecorder: UnifiedRecorder,
        connectionManager: DeviceConnectionManagerProtocol,
        fallbackOnDisconnect: Bool = true
    ) {
        self.unifiedRecorder = unifiedRecorder
        self.connectionManager = connectionManager
        self.fallbackOnDisconnect = fallbackOnDisconnect
        
        self.isRecordingPublisher = isRecordingSubject.eraseToAnyPublisher()
        self.recordingSourcePublisher = recordingSourceSubject.eraseToAnyPublisher()
        self.recordingErrorPublisher = recordingErrorSubject.eraseToAnyPublisher()
        self.didSwitchSourcePublisher = didSwitchSourceSubject.eraseToAnyPublisher()
        
        setupSubscriptions()
    }
    
    deinit {
        activeRecordingTask?.cancel()
        connectionStateCancellable?.cancel()
    }
    
    // MARK: - Private Setup
    
    private func setupSubscriptions() {
        unifiedRecorder.isRecordingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecordingSubject.send(isRecording)
            }
            .store(in: &cancellables)
        
        unifiedRecorder.recordingSourcePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] source in
                self?.recordingSourceSubject.send(source)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Starts a new recording session
    /// Automatically selects the best available source (BLE preferred, internal mic fallback)
    public func startRecording() {
        guard !isRecordingSubject.value else {
            ScribeLogger.warning("Recording already in progress, cannot start new recording", category: .audio)
            recordingErrorSubject.send(.recordingAlreadyInProgress)
            return
        }
        
        isTransitioningSource = false
        
        unifiedRecorder.startRecording()
        
        if isRecordingSubject.value {
            setupConnectionStateMonitoring()
            ScribeLogger.info("Recording orchestrator started recording", category: .audio)
        } else {
            ScribeLogger.error("Failed to start recording via unified recorder", category: .audio)
            recordingErrorSubject.send(.failedToStartRecording)
        }
    }
    
    /// Stops the current recording session and finalizes the file
    /// - Returns: The completed Recording object, or nil if no recording was active
    public func stopRecording() async -> Recording? {
        guard isRecordingSubject.value else {
            ScribeLogger.warning("No recording in progress to stop", category: .audio)
            return nil
        }
        
        connectionStateCancellable?.cancel()
        connectionStateCancellable = nil
        
        let recording = await unifiedRecorder.stopRecording()
        
        if recording != nil {
            ScribeLogger.info("Recording orchestrator stopped recording successfully", category: .audio)
        } else {
            ScribeLogger.error("Recording orchestrator failed to stop recording properly", category: .audio)
            recordingErrorSubject.send(.failedToStopRecording)
        }
        
        return recording
    }
    
    /// Manually switches the recording source mid-recording
    /// - Parameter newSource: The source to switch to
    public func switchSource(to newSource: RecordingSource) {
        guard isRecordingSubject.value else {
            ScribeLogger.warning("Cannot switch source: no recording in progress", category: .audio)
            recordingErrorSubject.send(.noActiveRecording)
            return
        }
        
        guard let currentSource = recordingSourceSubject.value, currentSource != newSource else {
            ScribeLogger.warning("Cannot switch source: already using requested source or no current source", category: .audio)
            return
        }
        
        performSourceSwitch(from: currentSource, to: newSource)
    }
    
    /// Updates the fallback behavior on BLE disconnect
    /// - Parameter enabled: Whether to fallback to internal mic when BLE disconnects
    public func setFallbackOnDisconnect(_ enabled: Bool) {
        fallbackOnDisconnect = enabled
        ScribeLogger.info("BLE disconnect fallback set to: \(enabled)", category: .audio)
    }
    
    // MARK: - Connection State Monitoring
    
    private func setupConnectionStateMonitoring() {
        connectionStateCancellable = connectionManager.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
    }
    
    private func handleConnectionStateChange(_ state: ConnectionState) {
        guard isRecordingSubject.value else { return }
        
        switch state {
        case .disconnected, .failed:
            handleBLEDisconnect()
        case .connected, .binding, .initializing, .initialized, .bound:
            break
        case .connecting, .reconnecting:
            break
        }
    }
    
    private func handleBLEDisconnect() {
        guard let currentSource = recordingSourceSubject.value,
              currentSource == .rawBle else {
            return
        }
        
        ScribeLogger.warning("BLE disconnected during recording", category: .audio)
        
        if fallbackOnDisconnect {
            ScribeLogger.info("Attempting to fallback to internal mic", category: .audio)
            performSourceSwitch(from: .rawBle, to: .rawInternal)
        } else {
            ScribeLogger.info("Fallback disabled, stopping recording cleanly", category: .audio)
            activeRecordingTask = Task { [weak self] in
                _ = await self?.stopRecording()
            }
        }
    }
    
    // MARK: - Source Switching
    
    private func performSourceSwitch(from currentSource: RecordingSource, to newSource: RecordingSource) {
        guard !isTransitioningSource else {
            ScribeLogger.warning("Source transition already in progress, ignoring request", category: .audio)
            recordingErrorSubject.send(.sourceTransitionInProgress)
            return
        }
        
        isTransitioningSource = true
        
        ScribeLogger.info("Switching recording source from \(currentSource) to \(newSource)", category: .audio)
        
        activeRecordingTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await executeSourceSwitch(from: currentSource, to: newSource)
                self.didSwitchSourceSubject.send((from: currentSource, to: newSource))
                ScribeLogger.info("Source switch completed successfully", category: .audio)
            } catch {
                ScribeLogger.error("Source switch failed: \(error.localizedDescription)", category: .audio)
                self.recordingErrorSubject.send(.sourceSwitchFailed(error.localizedDescription))
            }
            
            self.isTransitioningSource = false
        }
    }
    
    private func executeSourceSwitch(from currentSource: RecordingSource, to newSource: RecordingSource) async throws {
        await stopCurrentRecordingWithoutFinalizing()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await startRecordingWithSource(newSource)
        
        guard isRecordingSubject.value else {
            throw RecordingOrchestratorError.failedToStartRecording
        }
    }
    
    private func stopCurrentRecordingWithoutFinalizing() async {
        connectionStateCancellable?.cancel()
        connectionStateCancellable = nil
        
        _ = await unifiedRecorder.stopRecording()
    }
    
    private func startRecordingWithSource(_ source: RecordingSource) async {
        unifiedRecorder.startRecording()
        
        if isRecordingSubject.value {
            setupConnectionStateMonitoring()
        }
    }
    
    // MARK: - Recording State Queries
    
    /// Returns whether a recording is currently active
    public var isRecording: Bool {
        isRecordingSubject.value
    }
    
    /// Returns the current recording source, if any
    public var currentSource: RecordingSource? {
        recordingSourceSubject.value
    }
    
    /// Returns whether a source transition is currently in progress
    public var isSwitchingSource: Bool {
        isTransitioningSource
    }
}

// MARK: - Errors

public enum RecordingOrchestratorError: Error, Equatable {
    case recordingAlreadyInProgress
    case noActiveRecording
    case failedToStartRecording
    case failedToStopRecording
    case sourceSwitchFailed(String)
    case sourceTransitionInProgress
    case bleDisconnectNoFallback
    
    public static func == (lhs: RecordingOrchestratorError, rhs: RecordingOrchestratorError) -> Bool {
        switch (lhs, rhs) {
        case (.recordingAlreadyInProgress, .recordingAlreadyInProgress),
             (.noActiveRecording, .noActiveRecording),
             (.failedToStartRecording, .failedToStartRecording),
             (.failedToStopRecording, .failedToStopRecording),
             (.sourceTransitionInProgress, .sourceTransitionInProgress),
             (.bleDisconnectNoFallback, .bleDisconnectNoFallback):
            return true
        case (.sourceSwitchFailed(let lhsReason), .sourceSwitchFailed(let rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}

extension RecordingOrchestratorError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .recordingAlreadyInProgress:
            return "A recording is already in progress"
        case .noActiveRecording:
            return "No active recording to perform this operation"
        case .failedToStartRecording:
            return "Failed to start recording"
        case .failedToStopRecording:
            return "Failed to stop recording properly"
        case .sourceSwitchFailed(let reason):
            return "Failed to switch recording source: \(reason)"
        case .sourceTransitionInProgress:
            return "A source transition is already in progress"
        case .bleDisconnectNoFallback:
            return "BLE disconnected and no fallback source available"
        }
    }
}
