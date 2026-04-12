import AVFoundation
import Combine
import UIKit

/// Records audio from the internal microphone using AVAudioRecorder
/// Implements AudioRecorderProtocol for unified audio recording interface
public final class InternalMicRecorder: NSObject, AudioRecorderProtocol, AVAudioRecorderDelegate {
    
    // MARK: - AudioRecorderProtocol Properties
    
    public let isRecordingPublisher: AnyPublisher<Bool, Never>
    public let audioDataPublisher: AnyPublisher<Data, Never>
    
    // MARK: - Private Properties
    
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    
    private var audioRecorder: AVAudioRecorder?
    private var outputFileURL: URL?
    
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
            try setupRecorder()
            
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
            
            ScribeLogger.info("Audio session configured - category: playAndRecord", category: .audio)
        } catch {
            ScribeLogger.error("Failed to configure audio session: \(error.localizedDescription)", category: .audio)
            throw InternalMicRecorderError.audioSessionConfigurationFailed
        }
    }
    
    // MARK: - Recorder Setup
    
    private func setupRecorder() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString
        let fileURL = documentsPath.appendingPathComponent("\(fileName).m4a")
        
        outputFileURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            let success = audioRecorder?.record() ?? false
            guard success else {
                ScribeLogger.error("Failed to start recorder", category: .audio)
                throw InternalMicRecorderError.recorderStartFailed
            }
            
            ScribeLogger.info("Recorder started: \(fileURL.lastPathComponent)", category: .audio)
        } catch {
            ScribeLogger.error("Failed to create recorder: \(error.localizedDescription)", category: .audio)
            throw InternalMicRecorderError.recorderCreationFailed
        }
    }
    
    // MARK: - Route Change Handling
    
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
        
        let duration = audioRecorder?.currentTime ?? 0
        audioRecorder?.stop()
        
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
        audioRecorder?.stop()
        audioRecorder = nil
        outputFileURL = nil
        isRecordingSubject.send(false)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            ScribeLogger.warning("Recorder finished with failure", category: .audio)
        }
    }
}

// MARK: - Errors

public enum InternalMicRecorderError: Error {
    case audioSessionConfigurationFailed
    case recorderCreationFailed
    case recorderStartFailed
    case recordingNotActive
}

extension InternalMicRecorderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session"
        case .recorderCreationFailed:
            return "Failed to create audio recorder"
        case .recorderStartFailed:
            return "Failed to start audio recorder"
        case .recordingNotActive:
            return "No active recording"
        }
    }
}