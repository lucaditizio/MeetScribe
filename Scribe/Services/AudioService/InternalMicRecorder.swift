import AVFoundation
import Combine
import UIKit

/// Records audio from the internal microphone using AVAudioEngine
/// Implements AudioRecorderProtocol for unified audio recording interface
public final class InternalMicRecorder: NSObject, AudioRecorderProtocol {
    
    // MARK: - AudioRecorderProtocol Properties
    
    public let isRecordingPublisher: AnyPublisher<Bool, Never>
    public let audioDataPublisher: AnyPublisher<Data, Never>
    
    // MARK: - Private Properties
    
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    
    private var audioEngine: AVAudioEngine?
    private var opusEncoder: OpusEncoder?
    private var outputFileURL: URL?
    private var fileHandle: FileHandle?
    
    private let audioConfig = AudioConfig()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private var routeChangeObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    public override init() {
        self.isRecordingPublisher = isRecordingSubject.eraseToAnyPublisher()
        self.audioDataPublisher = audioDataSubject.eraseToAnyPublisher()
        super.init()
        setupRouteChangeObserver()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - AudioRecorderProtocol Methods
    
    public func startRecording(source: RecordingSource) {
        guard !isRecordingSubject.value else {
            ScribeLogger.warning("Recording already in progress", category: .audio)
            return
        }
        
        do {
            try configureAudioSession()
            try setupAudioEngine()
            try setupOutputFile()
            
            hapticGenerator.impactOccurred()
            isRecordingSubject.send(true)
            
            ScribeLogger.info("Internal mic recording started", category: .audio)
        } catch {
            ScribeLogger.error("Failed to start recording: \(error.localizedDescription)", category: .audio)
            cleanup()
        }
    }
    
    public func stopRecording() async -> Recording? {
        guard isRecordingSubject.value else {
            ScribeLogger.warning("No recording in progress to stop", category: .audio)
            return nil
        }
        
        await MainActor.run {
            hapticGenerator.impactOccurred()
        }
        isRecordingSubject.send(false)
        
        let recording = await finalizeRecording()
        cleanup()
        
        ScribeLogger.info("Internal mic recording stopped", category: .audio)
        
        return recording
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try session.setActive(true)
            
            // Attempt to set preferred sample rate
            try session.setPreferredSampleRate(audioConfig.sampleRate)
            
            ScribeLogger.info("Audio session configured - category: playAndRecord, sampleRate: \(audioConfig.sampleRate)", category: .audio)
        } catch {
            ScribeLogger.error("Failed to configure audio session: \(error.localizedDescription)", category: .audio)
            throw InternalMicRecorderError.audioSessionConfigurationFailed
        }
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            ScribeLogger.error("Failed to create audio engine", category: .audio)
            throw InternalMicRecorderError.audioEngineCreationFailed
        }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Target format: 16kHz mono Float32 PCM
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: audioConfig.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            ScribeLogger.error("Failed to create target audio format", category: .audio)
            throw InternalMicRecorderError.formatCreationFailed
        }
        
        // Create Opus encoder
        do {
            opusEncoder = try OpusEncoder.makeDefault()
        } catch {
            ScribeLogger.error("Failed to create Opus encoder: \(error.localizedDescription)", category: .audio)
            throw InternalMicRecorderError.encoderCreationFailed
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(audioConfig.frameSize), format: targetFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            ScribeLogger.info("Audio engine started successfully", category: .audio)
        } catch {
            ScribeLogger.error("Failed to start audio engine: \(error.localizedDescription)", category: .audio)
            throw InternalMicRecorderError.audioEngineStartFailed
        }
    }
    
    // MARK: - Output File Setup
    
    private func setupOutputFile() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString
        let fileURL = documentsPath.appendingPathComponent("\(fileName).\(audioConfig.fileExtension)")
        
        outputFileURL = fileURL
        
        // Create empty file
        do {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            fileHandle = try FileHandle(forWritingTo: fileURL)
            ScribeLogger.info("Output file created: \(fileURL.lastPathComponent)", category: .audio)
        } catch {
            ScribeLogger.error("Failed to create output file: \(error.localizedDescription)", category: .audio)
            throw InternalMicRecorderError.fileCreationFailed
        }
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let opusEncoder = opusEncoder,
              let fileHandle = fileHandle,
              let audioData = buffer.floatChannelData?[0] else {
            ScribeLogger.error("Invalid audio buffer state", category: .audio)
            return
        }
        
        let frameCount = Int(buffer.frameLength)
        let expectedFrameCount = audioConfig.frameSize
        
        // Process complete frames only
        guard frameCount == expectedFrameCount else {
            ScribeLogger.warning("Incomplete frame: \(frameCount) vs expected \(expectedFrameCount)", category: .audio)
            return
        }
        
        // Convert to array
        let pcmData = Array(UnsafeBufferPointer(start: audioData, count: frameCount))
        
        do {
            // Encode to Opus
            let opusPacket = try opusEncoder.encode(pcmData)
            
            // Write packet size (4 bytes) followed by packet data
            var packetSize = Int32(opusPacket.count)
            let sizeData = Data(bytes: &packetSize, count: MemoryLayout<Int32>.size)
            
            fileHandle.write(sizeData)
            fileHandle.write(opusPacket)
            
            // Emit audio data for subscribers
            audioDataSubject.send(opusPacket)
        } catch {
            ScribeLogger.error("Failed to encode audio: \(error.localizedDescription)", category: .audio)
        }
    }
    
    // MARK: - USB-C Plug & Play
    
    private func setupRouteChangeObserver() {
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            ScribeLogger.warning("Invalid route change notification", category: .audio)
            return
        }
        
        ScribeLogger.info("Audio route changed - reason: \(routeChangeReasonDescription(reason))", category: .audio)
        
        // Handle new device connection
        switch reason {
        case .newDeviceAvailable:
            setPreferredInputToUSB()
        case .oldDeviceUnavailable:
            ScribeLogger.info("Audio device disconnected", category: .audio)
        default:
            break
        }
    }
    
    private func setPreferredInputToUSB() {
        let session = AVAudioSession.sharedInstance()
        let currentRoute = session.currentRoute
        
        // Look for USB audio or headset mic
        for input in currentRoute.inputs {
            let portType = input.portType
            
            if portType == .usbAudio || portType == .headsetMic {
                do {
                    try session.setPreferredInput(input)
                    ScribeLogger.info("Preferred input set to: \(input.portName) (\(portType.rawValue))", category: .audio)
                } catch {
                    ScribeLogger.error("Failed to set preferred input: \(error.localizedDescription)", category: .audio)
                }
                return
            }
        }
        
        ScribeLogger.info("No USB/headset input found, using default", category: .audio)
    }
    
    private func routeChangeReasonDescription(_ reason: AVAudioSession.RouteChangeReason) -> String {
        switch reason {
        case .unknown: return "unknown"
        case .newDeviceAvailable: return "newDeviceAvailable"
        case .oldDeviceUnavailable: return "oldDeviceUnavailable"
        case .categoryChange: return "categoryChange"
        case .override: return "override"
        case .wakeFromSleep: return "wakeFromSleep"
        case .noSuitableRouteForCategory: return "noSuitableRouteForCategory"
        case .routeConfigurationChange: return "routeConfigurationChange"
        @unknown default: return "unknown(\(reason.rawValue))"
        }
    }
    
    // MARK: - Finalization
    
    private func finalizeRecording() async -> Recording? {
        guard let fileURL = outputFileURL else {
            ScribeLogger.error("No output file URL available", category: .audio)
            return nil
        }
        
        // Close file handle
        do {
            try fileHandle?.close()
        } catch {
            ScribeLogger.error("Failed to close file handle: \(error.localizedDescription)", category: .audio)
        }
        
        // Get file attributes for duration
        var duration: TimeInterval = 0
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? UInt64 {
                // Rough estimate: Opus at ~24kbps, adjust as needed
                duration = Double(fileSize) / 3000.0 // Approximate
            }
        } catch {
            ScribeLogger.error("Failed to get file attributes: \(error.localizedDescription)", category: .audio)
        }
        
        let recording = Recording(
            title: "Recording \(formatDate(Date()))",
            date: Date(),
            duration: duration,
            fileName: fileURL.lastPathComponent,
            filePath: fileURL.path,
            source: .rawInternal
        )
        
        ScribeLogger.info("Recording finalized: \(fileURL.lastPathComponent), duration: \(duration)s", category: .audio)
        
        return recording
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        // Stop audio engine
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        // Close file handle
        do {
            try fileHandle?.close()
        } catch {
            ScribeLogger.error("Failed to close file handle during cleanup: \(error.localizedDescription)", category: .audio)
        }
        fileHandle = nil
        
        // Reset state
        opusEncoder = nil
        outputFileURL = nil
        isRecordingSubject.send(false)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Errors

public enum InternalMicRecorderError: Error {
    case audioSessionConfigurationFailed
    case audioEngineCreationFailed
    case audioEngineStartFailed
    case formatCreationFailed
    case encoderCreationFailed
    case fileCreationFailed
    case recordingNotActive
}

extension InternalMicRecorderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session"
        case .audioEngineCreationFailed:
            return "Failed to create audio engine"
        case .audioEngineStartFailed:
            return "Failed to start audio engine"
        case .formatCreationFailed:
            return "Failed to create audio format"
        case .encoderCreationFailed:
            return "Failed to create Opus encoder"
        case .fileCreationFailed:
            return "Failed to create output file"
        case .recordingNotActive:
            return "No active recording"
        }
    }
}