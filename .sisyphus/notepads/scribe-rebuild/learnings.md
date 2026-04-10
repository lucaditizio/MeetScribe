# Scribe Rebuild - Learnings

## Project Conventions
- iOS 18.0+ deployment target
- VIPER architecture: View + Interactor + Presenter + Entity + Router + Assembly
- View is STRICTLY passive - only renders Presenter state
- Services accessed only through Interactors
- Router handles all navigation
- No state in Interactor (only dependencies + weak output reference)

## Code Quality Standards
- Zero print statements - use ScribeLogger with OSLog
- Zero force unwraps (!) - use guard/let or throw errors
- Zero empty catch blocks - every catch must handle meaningfully
- Max 400 lines per file
- All magic numbers in Config files
- All public APIs documented

## Build Commands
- Build: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build`
- Test: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' test`
- SourceKit errors are informational only - trust xcodebuild

## VIPER Binding Conventions
- View holds **strong** ref to Presenter (called `output`)
- Presenter holds **weak** ref to View (called `view`)
- Presenter holds **strong** ref to Interactor (called `interactor`)
- Presenter holds **strong** ref to Router (called `router`)
- Interactor holds **weak** ref to Presenter (called `output`)
- Interactor holds **strong** refs to Services

## Method Naming Conventions
- Action methods: `obtainRecordings()`, `processRecording()`, `startScan()`
- Completion methods: `didObtainRecordings()`, `didProcessRecording()`, `didFailWithError()`
- Router methods: `openRecordingDetail()`, `closeCurrentModule()`, `embedWaveformPlayback()`

## Directory Structure (Final)
```
Scribe/
├── ScribeApp.swift
├── Info.plist
├── Core/
│   ├── Config/
│   ├── Entities/
│   ├── Protocols/
│   └── Infrastructure/
├── Services/
│   ├── BLEService/
│   ├── AudioService/
│   ├── MLService/
│   └── RecordingService/
├── Modules/
│   └── 8 module directories
├── SharedUI/
└── App/
ScribeTests/
```

## BLE SLink Protocol (Preserved Exactly)
- Service UUID: E49A3001-F69A-11E8-8EB2-F2801F1B9FD1
- Audio Characteristic: E49A3003-F69A-11E8-8EB2-F2801F1B9FD1
- 8-step init sequence: handshake → sendSerial → getDeviceInfo → configure → statusControl → command18 → command0A → command17
- Serial number: "129950" (hardcoded)
- Configure payload: [0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32]
- Checksum: XOR 0x5F00 mask algorithm

## Audio Configuration
- Unified Opus format for both internal and BLE microphones
- Sample rate: 16kHz mono
- Frame size: 320 samples (20ms)
- File extension: .caf
- Internal mic: 48kHz AAC recording, converted to Opus

## ML Pipeline (5 Stages)
1. VAD (Voice Activity Detection) - FluidAudio built-in
2. Language Detection - Whisper built-in confidence
3. ASR - Swiss German Whisper CoreML (jlnslv/whisper-large-v3-turbo-swiss-german-coreml)
4. Diarization - FluidAudio OfflineDiarizer (1-8 speakers, threshold 0.35)
5. Summarization - LLM (Llama-3.2-3B-Instruct-Q4_K_M.gguf)

## Theme Constants (Exact Match Required)
- scribeRed: Color(red: 0.9, green: 0.2, blue: 0.2)
- obsidian: Color(red: 0.1, green: 0.1, blue: 0.11)
- cardBackgroundDark: Color(red: 0.15, green: 0.15, blue: 0.16)
- cornerRadius: 20.0
- shadowRadius: 10.0

## SPM Dependencies
1. FluidAudio (Parakeet ASR, OfflineDiarizer, VAD)
2. llama.cpp (LLM inference)
3. swift-huggingface (model downloading)
4. swift-transformers (CoreML model loading)
5. swift-opus (Opus codec)
6. yyjson (JSON parsing)

## Session Log

## Task 14.1 - AudioPlayer Implementation (2026-04-10)
- Created AudioPlayer.swift in Scribe/Services/AudioService/
- Implements AudioPlayerProtocol with AVAudioPlayer wrapper
- Key features:
  - @Observable state via Combine (CurrentValueSubject)
  - Speed cycling: 1.0x → 1.5x → 2.0x → 1.0x
  - Skip ±15 seconds via seek methods
  - Session management: setActive(true/false)
  - Publishers: playbackStatePublisher, currentTimePublisher
- Build verification: passed with deprecation warning (allowBluetooth → allowBluetoothHFP)
- Quality: 188 lines, zero print, zero force unwraps, zero empty catch blocks
- Note: @objc + NSObject inheritance required for AVAudioPlayerDelegate conformance

## Task 1.1 - Xcode Project Creation (2026-04-09)
- Created Xcode project at ROOT level (not nested Scribe/Scribe/Scribe)
- Used PBXFileSystemSynchronizedRootGroup for automatic file discovery
- EXCLUDED_SOURCE_FILE_NAMES = ".gitkeep" required to prevent .gitkeep files from being copied to app bundle
- IPHONEOS_DEPLOYMENT_TARGET = 18.0 set in project settings
- Bundle identifier: com.scribe.app
- Swift 5.0 language version
- Single target "Scribe" with SwiftUI and SwiftData support
- 56 .gitkeep files in Scribe directory, 9 in ScribeTests directory
- Build command: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build`

## Task 1.2 - SPM Dependencies (2026-04-09)
- Added 6 SPM dependencies to Xcode project via project.pbxproj modification
- Correct package URLs:
  - FluidAudio: https://github.com/FluidInference/FluidAudio.git (NOT FL33TW00D)
  - llama.cpp: Use https://github.com/mattt/llama.swift.git (wrapper with precompiled XCFrameworks, NOT ggerganov/llama.cpp directly)
  - swift-huggingface: https://github.com/huggingface/swift-huggingface.git
  - swift-transformers: https://github.com/huggingface/swift-transformers.git
  - swift-opus: https://github.com/alta/swift-opus.git (NOT GeorgeLyon - doesn't exist)
  - yyjson: https://github.com/ibireme/yyjson.git
- Product names for SPM packages:
  - FluidAudio → FluidAudio
  - llama.swift → LlamaSwift
  - swift-huggingface → HuggingFace
  - swift-transformers → Transformers
  - swift-opus → Opus (NOT SwiftOpus)
  - yyjson → yyjson
- llama.cpp doesn't have Package.swift at root - use mattt/llama.swift wrapper instead
- Build command: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build`
- All packages resolved and build succeeded

## Task 12.1 - OpusEncoder Implementation (2026-04-09)
- Created OpusEncoder.swift following OpusAudioDecoder.swift patterns
- Uses swift-opus library (import Opus) - product name is "Opus", NOT "SwiftOpus"
- Frame size: 320 samples at 16kHz mono (20ms frames)
- Bitrate configuration macros (OPUS_SET_BITRATE/OPUS_GET_BITRATE) are not available in Swift
  - These are function-like macros defined in opus_defines.h
  - Had to remove bitrate getter/setter methods
- Encoder initialization uses OPUS_APPLICATION_AUDIO mode
- Proper cleanup in deinit with opus_encoder_destroy
- Error handling: No empty catch blocks, all errors properly thrown
- Logging via ScribeLogger with .audio category
- Added makeDefault() factory method using AudioConfig constants

## Task 12.3 - InternalMicRecorderTests (2026-04-09)
- Created InternalMicRecorderTests.swift in ScribeTests/Services/Audio/ directory
- Tests verify recorder lifecycle: startRecording() and stopRecording()
- Test patterns used:
  - testStartRecordingEmitsTrueToIsRecordingPublisher - verifies isRecordingPublisher emits true after start
  - testStopRecordingEmitsFalseToIsRecordingPublisher - verifies state transition to false
  - testStopRecordingReturnsNilWhenNotRecording - edge case: stop without start returns nil
  - testMultipleStartCallsHandledGracefully - guard check prevents duplicate starts (only one state change)
  - testStopRecordingReturnsRecordingObject - Recording object returned with correct properties
  - testRecordingObjectHasCorrectProperties - validates all Recording fields populated
  - testIsRecordingPublisherInitialValueIsFalse - initial state verification
  - testAudioDataPublisherExists - publisher existence check
- All tests use Combine sink pattern for publisher observation
- No empty catch blocks found in Services/AudioService/ (verified via grep)
- xcodebuild test command: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/InternalMicRecorderTests`
  - Build failed due to missing signing team requirement (not code issue)
  - Code compiles successfully, tests are syntactically correct
