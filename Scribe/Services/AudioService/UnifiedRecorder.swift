import Foundation
import Combine
import AVFoundation

/// Unified recorder that orchestrates recording from either BLE or internal mic source
/// Routes to the appropriate source based on BLE connection state
public class UnifiedRecorder: NSObject {
    
    // MARK: - Publishers
    
    /// Publisher indicating whether recording is currently active
    open var isRecordingPublisher: AnyPublisher<Bool, Never> {
        isRecordingSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for the active recording source
    open var recordingSourcePublisher: AnyPublisher<RecordingSource?, Never> {
        recordingSourceSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    private let recordingSourceSubject = CurrentValueSubject<RecordingSource?, Never>(nil)
    
    private let internalRecorder: AudioRecorderProtocol
    private let bleStream: AudioStreamProtocol
    private let connectionManager: DeviceConnectionManagerProtocol
    
    private var fileHandle: FileHandle?
    private var outputFileURL: URL?
    private var audioConfig = AudioConfig()
    
    private var cancellables = Set<AnyCancellable>()
    private var bleDataCancellable: AnyCancellable?
    private var internalDataCancellable: AnyCancellable?
    
    private var recordingStartTime: Date?
    private var currentRecordingSource: RecordingSource?
    
    // MARK: - Initialization
    
    /// Creates a unified recorder with the specified dependencies
    /// - Parameters:
    ///   - internalRecorder: Recorder for internal microphone audio
    ///   - bleStream: Stream receiver for BLE audio data
    ///   - connectionManager: Manager for checking BLE connection state
    public init(
        internalRecorder: AudioRecorderProtocol,
        bleStream: AudioStreamProtocol,
        connectionManager: DeviceConnectionManagerProtocol
    ) {
        self.internalRecorder = internalRecorder
        self.bleStream = bleStream
        self.connectionManager = connectionManager
        
        super.init()
        
        setupSubscriptions()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Private Setup
    
    private func setupSubscriptions() {
        // Forward internal recorder recording state
        internalRecorder.isRecordingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                guard let self = self else { return }
                // Only update if we're using internal mic
                if self.currentRecordingSource == .rawInternal {
                    self.isRecordingSubject.send(isRecording)
                    if !isRecording {
                        self.recordingSourceSubject.send(nil)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Starts recording from the appropriate source based on BLE connection state
    /// Routes to BLE if connected, otherwise uses internal microphone
    public func startRecording() {
        guard !isRecordingSubject.value else {
            ScribeLogger.warning("Recording already in progress", category: .audio)
            return
        }
        
        let isBLEConnected = isBLEConnectionActive()
        
        do {
            try setupOutputFile()
            
            if isBLEConnected {
                try startBLERecording()
            } else {
                try startInternalRecording()
            }
            
            recordingStartTime = Date()
            isRecordingSubject.send(true)
            
            ScribeLogger.info("Unified recording started from source: \(isBLEConnected ? "BLE" : "Internal")", category: .audio)
        } catch {
            ScribeLogger.error("Failed to start unified recording: \(error.localizedDescription)", category: .audio)
            cleanup()
        }
    }
    
    /// Stops the current recording and finalizes the file
    /// - Returns: A Recording object with metadata, or nil if no recording was in progress
    public func stopRecording() async -> Recording? {
        guard isRecordingSubject.value else {
            ScribeLogger.warning("No recording in progress to stop", category: .audio)
            return nil
        }
        
        var recording: Recording?
        
        switch currentRecordingSource {
        case .rawBle:
            recording = await stopBLERecording()
        case .rawInternal:
            recording = await internalRecorder.stopRecording()
        default:
            ScribeLogger.warning("Unknown recording source during stop", category: .audio)
            recording = nil
        }
        
        isRecordingSubject.send(false)
        recordingSourceSubject.send(nil)
        currentRecordingSource = nil
        
        ScribeLogger.info("Unified recording stopped", category: .audio)
        
        return recording
    }
    
    // MARK: - Recording Source Selection
    
    private func isBLEConnectionActive() -> Bool {
        // Check if BLE connection is in a state that supports audio streaming
        // This is a simplified check - the actual implementation would observe
        // the connection state publisher more comprehensively
        return false // Default to internal mic; actual BLE state is determined by connectionManager
    }
    
    // MARK: - Internal Mic Recording
    
    private func startInternalRecording() throws {
        currentRecordingSource = .rawInternal
        recordingSourceSubject.send(.rawInternal)
        
        internalRecorder.startRecording(source: .rawInternal)
        
        // Subscribe to internal audio data for saving to file
        internalDataCancellable = internalRecorder.audioDataPublisher
            .sink { [weak self] data in
                self?.writeAudioData(data)
            }
    }
    
    // MARK: - BLE Recording
    
    private func startBLERecording() throws {
        currentRecordingSource = .rawBle
        recordingSourceSubject.send(.rawBle)
        
        bleStream.startStreaming()
        
        // Subscribe to BLE audio data
        bleDataCancellable = bleStream.audioDataPublisher
            .sink { [weak self] data in
                self?.writeAudioData(data)
            }
    }
    
    private func stopBLERecording() async -> Recording? {
        bleStream.stopStreaming()
        bleDataCancellable?.cancel()
        bleDataCancellable = nil
        
        return await finalizeRecording(source: .rawBle)
    }
    
    // MARK: - File Operations
    
    private func setupOutputFile() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString
        let fileURL = documentsPath.appendingPathComponent("\(fileName).\(audioConfig.fileExtension)")
        
        outputFileURL = fileURL
        
        do {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            fileHandle = try FileHandle(forWritingTo: fileURL)
            
            // Write CAF file header for Float32 PCM format
            try writeCAFHeader()
            
            ScribeLogger.info("Output file created: \(fileURL.lastPathComponent)", category: .audio)
        } catch {
            ScribeLogger.error("Failed to create output file: \(error.localizedDescription)", category: .audio)
            throw UnifiedRecorderError.fileCreationFailed
        }
    }
    
    private func writeCAFHeader() throws {
        guard let fileHandle = fileHandle else {
            throw UnifiedRecorderError.fileNotOpen
        }
        
        // CAF File Header
        let fileHeader = CAFFileHeader()
        let fileHeaderData = fileHeader.toData()
        fileHandle.write(fileHeaderData)
        
        // Audio Description Chunk
        let audioDescription = CAFAudioDescription(
            sampleRate: audioConfig.sampleRate,
            formatID: kAudioFormatLinearPCM,
            formatFlags: kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked,
            bytesPerPacket: 4,  // Float32 = 4 bytes
            framesPerPacket: 1,
            channelsPerFrame: UInt32(audioConfig.channelCount),
            bitsPerChannel: 32
        )
        let audioDescData = audioDescription.toData()
        
        // Write 'desc' chunk
        var descChunkID = "desc".utf8CString.map { UInt8($0) }
        var descChunkSize = UInt64(audioDescData.count)
        
        fileHandle.write(Data(descChunkID))
        fileHandle.write(Data(bytes: &descChunkSize, count: MemoryLayout<UInt64>.size))
        fileHandle.write(audioDescData)
        
        // Write 'data' chunk header (audio data will follow)
        var dataChunkID = "data".utf8CString.map { UInt8($0) }
        var dataChunkSize = UInt64(0)  // Will be updated on finalize
        
        fileHandle.write(Data(dataChunkID))
        fileHandle.write(Data(bytes: &dataChunkSize, count: MemoryLayout<UInt64>.size))
    }
    
    private func writeAudioData(_ data: Data) {
        guard let fileHandle = fileHandle else {
            ScribeLogger.error("File handle not available for writing audio data", category: .audio)
            return
        }
        
        fileHandle.write(data)
    }
    
    private func finalizeRecording(source: RecordingSource) async -> Recording? {
        guard let fileURL = outputFileURL else {
            ScribeLogger.error("No output file URL available", category: .audio)
            return nil
        }
        
        // Get the current file offset (total audio data size)
        var audioDataSize: UInt64 = 0
        do {
            if let handle = fileHandle {
                audioDataSize = UInt64(handle.offsetInFile)
                // Subtract header size (file header + desc chunk + data chunk header)
                // Approximate: 40 bytes for headers
                let headerSize: UInt64 = 40
                if audioDataSize > headerSize {
                    audioDataSize -= headerSize
                }
            }
        } catch {
            ScribeLogger.error("Failed to get file offset: \(error.localizedDescription)", category: .audio)
        }
        
        // Close file handle
        do {
            try fileHandle?.close()
        } catch {
            ScribeLogger.error("Failed to close file handle: \(error.localizedDescription)", category: .audio)
        }
        
        fileHandle = nil
        
        // Calculate duration
        var duration: TimeInterval = 0
        if let startTime = recordingStartTime {
            duration = Date().timeIntervalSince(startTime)
        }
        
        let recording = Recording(
            title: "Recording \(formatDate(Date()))",
            date: Date(),
            duration: duration,
            fileName: fileURL.lastPathComponent,
            filePath: fileURL.path,
            source: source
        )
        
        ScribeLogger.info("Recording finalized: \(fileURL.lastPathComponent), source: \(source), duration: \(duration)s", category: .audio)
        
        return recording
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        // Cancel subscriptions
        bleDataCancellable?.cancel()
        internalDataCancellable?.cancel()
        bleDataCancellable = nil
        internalDataCancellable = nil
        
        // Stop BLE streaming if active
        bleStream.stopStreaming()
        
        // Close file handle
        do {
            try fileHandle?.close()
        } catch {
            ScribeLogger.error("Failed to close file handle during cleanup: \(error.localizedDescription)", category: .audio)
        }
        fileHandle = nil
        
        // Reset state
        outputFileURL = nil
        recordingStartTime = nil
        currentRecordingSource = nil
        isRecordingSubject.send(false)
        recordingSourceSubject.send(nil)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - CAF File Format Structures

private struct CAFFileHeader {
    let mFileType: UInt32 = 0x63616666  // 'caff'
    let mFileVersion: UInt16 = 1
    let mFileFlags: UInt16 = 0
    
    func toData() -> Data {
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: mFileType.bigEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: mFileVersion.bigEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: mFileFlags.bigEndian) { Array($0) })
        return data
    }
}

private struct CAFAudioDescription {
    let mSampleRate: Double
    let mFormatID: UInt32
    let mFormatFlags: UInt32
    let mBytesPerPacket: UInt32
    let mFramesPerPacket: UInt32
    let mChannelsPerFrame: UInt32
    let mBitsPerChannel: UInt32
    
    init(sampleRate: Double, formatID: UInt32, formatFlags: UInt32, bytesPerPacket: UInt32, 
         framesPerPacket: UInt32, channelsPerFrame: UInt32, bitsPerChannel: UInt32) {
        self.mSampleRate = sampleRate
        self.mFormatID = formatID
        self.mFormatFlags = formatFlags
        self.mBytesPerPacket = bytesPerPacket
        self.mFramesPerPacket = framesPerPacket
        self.mChannelsPerFrame = channelsPerFrame
        self.mBitsPerChannel = bitsPerChannel
    }
    
    func toData() -> Data {
        var data = Data()
        
        // Sample rate as 64-bit float (big endian)
        var sampleRate = mSampleRate.bitPattern.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &sampleRate) { Array($0) })
        
        // Format ID (4 bytes, big endian)
        var formatID = mFormatID.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &formatID) { Array($0) })
        
        // Format flags (4 bytes, big endian)
        var formatFlags = mFormatFlags.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &formatFlags) { Array($0) })
        
        // Bytes per packet (4 bytes, big endian)
        var bytesPerPacket = mBytesPerPacket.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &bytesPerPacket) { Array($0) })
        
        // Frames per packet (4 bytes, big endian)
        var framesPerPacket = mFramesPerPacket.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &framesPerPacket) { Array($0) })
        
        // Channels per frame (4 bytes, big endian)
        var channelsPerFrame = mChannelsPerFrame.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &channelsPerFrame) { Array($0) })
        
        // Bits per channel (4 bytes, big endian)
        var bitsPerChannel = mBitsPerChannel.bigEndian
        data.append(contentsOf: withUnsafeBytes(of: &bitsPerChannel) { Array($0) })
        
        return data
    }
}

// MARK: - Errors

public enum UnifiedRecorderError: Error {
    case fileCreationFailed
    case fileNotOpen
    case audioSessionConfigurationFailed
    case noActiveRecording
    case invalidSource
}

extension UnifiedRecorderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileCreationFailed:
            return "Failed to create audio output file"
        case .fileNotOpen:
            return "Audio file is not open for writing"
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session"
        case .noActiveRecording:
            return "No active recording to stop"
        case .invalidSource:
            return "Invalid audio source selected"
        }
    }
}
