# MeetScribe — Complete Rebuild from Scratch (VIPER Architecture)

## TL;DR

> **Quick Summary**: Rebuild the entire MeetScribe iOS app from scratch using VIPER clean architecture (full granularity, strict View passivity, Router per module), eliminating all code quality issues while preserving exact UI look/feel, proprietary BLE SLink microphone protocol, and enhancing the ML pipeline with VAD, Swiss German ASR, and config-driven model swapping.
>
> **Deliverables**:
> - Complete iOS app (single Xcode target, ~60+ Swift files in VIPER module structure)
> - 8 VIPER modules: RecordingList, RecordingDetail, WaveformPlayback, Transcript, Summary, MindMap, AgentGenerating, DeviceSettings
> - Shared Services layer: BLE, Audio, ML, Recording
> - Core layer: Entities, Protocols, Config, Infrastructure
> - BLE SLink protocol preserved exactly (proprietary, reverse-engineered)
> - Unified Opus audio format for both internal and BLE microphones
> - ML pipeline: VAD → Language Detection → Swiss German Whisper ASR → Diarization → LLM Summary
> - Config-driven model swapping via PipelineConfig
> - Pixel-perfect UI match (Theme.swift, all animations, dark mode)
> - TDD test suite with 70%+ domain coverage
> - Updated README with current architecture
>
> **Estimated Effort**: Large
> **Execution Model**: Strict Sequential — one sub-task at a time, orchestrator verifies each
> **Critical Path**: Scaffolding → Core → Services → VIPER Modules → Views → App Wiring

---

## Context

### Original Request
User wants to rebuild Scribe (now MeetScribe) from scratch because "the current application was pasted together over different, uncoordinated steps." Key concerns: code quality, clean file structure (eliminate Scribe/Scribe/Scribe nesting), unified audio format, optimized ML pipeline with VAD and language detection, while preserving UI look/feel and proprietary BLE logic.

### Interview Summary

**Key Discussions**:
- **Architecture**: VIPER clean architecture (The Book of VIPER, Rambler&Co adaptation) with full granularity modules, strict View passivity, and Router per module
- **Audio format**: Opus for both internal and BLE microphones (unified)
- **VAD**: FluidAudio's built-in VAD
- **ASR**: Swiss German Whisper CoreML (jlnslv/whisper-large-v3-turbo-swiss-german-coreml) as primary, fallback to general model
- **Language detection**: Use Whisper's built-in language confidence as classifier
- **Model swapping**: Config-driven via PipelineConfig
- **Module decomposition**: 8 modules (RecordingList, RecordingDetail, WaveformPlayback, Transcript, Summary, MindMap, AgentGenerating, DeviceSettings)
- **View passivity**: Strict — View ONLY renders Presenter state and forwards user actions. Zero business logic in View.
- **Router strategy**: Dedicated Router per module for navigation
- **Test strategy**: TDD with clear Xcode build/test strategy; human-in-the-loop for verification
- **Target iOS**: iOS 18.0 (IPHONEOS_DEPLOYMENT_TARGET = 18.0)
- **Target device**: iPhone 15 Plus
- **Apple Notes export**: Removed from scope
- **BLE serial**: Hardcoded "129950" for now, architecture for dynamic extraction later
- **File exclusivity**: Only one sub-agent edits a file at a time (serial execution guarantees this)
- **CRITICAL**: This plan runs in an EMPTY directory with NO existing files. All code must be created from scratch. The .sisyphus folder will be moved to a new project called MeetScribe.

**Research Findings**:
- 23 current Swift files, triple nesting, 133 print statements, 1 test file
- BLE SLink: 8-step init, custom GATT services, Opus 16kHz mono, 4 source files
- ML pipeline: 4 sequential stages, peak ~2.1GB RAM on 6GB device
- UI: Theme.swift (5 colors), scribeCardStyle, dark mode forced, 6 main views
- Dependencies: FluidAudio, LLM.swift, swift-huggingface, swift-transformers, swift-opus, yyjson
- VIPER (Rambler&Co): Module = View + Interactor + Presenter + Entity + Router + Assembly; View passive; Interactor holds no state; Services injected into Interactors; ModuleInput/ModuleOutput for inter-module communication; DataDisplayManager for table/collection logic
- Xcode build: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus'` verified working
- **No .xcodeproj exists in current repo** — the project has source code but no Xcode project file, Package.swift, or Info.plist. Everything must be created from scratch.

### Metis Review

**Identified Gaps (addressed)**:
- Missing acceptance criteria for ML stages → Added timeout, cancellation, progress tracking
- Scope creep risks → Explicitly locked out: real-time transcription, recording editing, export formats beyond current
- TDD concerns for BLE → Protocol-based mocking strategy defined
- VIPER layering → Full module structure with Assembly, Interactor, Presenter, Router per module
- Edge cases → BLE disconnect mid-recording, empty transcripts, app backgrounding during pipeline
- Guardrails → Zero print statements, no force unwraps, no empty catch blocks, max 400 lines per file
- File exclusivity → Guaranteed by serial execution (no parallelism)
- Local model task sizing → Each sub-task touches 1-3 files max

---

## Work Objectives

### Core Objective
Rebuild MeetScribe from scratch with VIPER architecture, preserving all existing functionality while dramatically improving code quality, unifying audio format, and enhancing the ML pipeline.

### Concrete Deliverables
- ~60+ Swift files in VIPER module structure under single Xcode target
- 8 VIPER modules with full stacks (Assembly, Interactor, Presenter, Router, View)
- Shared Services layer (BLE, Audio, ML, Recording)
- Core layer (Entities, Protocols, Config, Infrastructure)
- BLE SLink protocol (exact copy of proprietary logic)
- Unified Opus audio recording pipeline
- Enhanced ML pipeline with VAD and Swiss German ASR
- Pixel-perfect UI match
- TDD test suite
- Updated README

### Definition of Done
- [ ] `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build` succeeds with zero errors
- [ ] `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' test` passes all tests
- [ ] Zero print statements in production code
- [ ] Zero force unwraps (`!`) in production code
- [ ] Zero empty catch blocks
- [ ] All files under 400 lines
- [ ] All public APIs have documentation comments
- [ ] All magic numbers extracted to Config files
- [ ] BLE connection works with real hardware (human verification)
- [ ] Recording → ML pipeline → transcript/summary/mind map works end-to-end (human verification)
- [ ] All VIPER modules follow strict View passivity — no business logic in View layer

### Must Have
- Exact UI look/feel (colors, fonts, icons, animations, dark mode)
- Proprietary BLE SLink protocol (8-step init, custom GATT, Opus decode)
- Dual recording (internal mic + BLE mic) with unified Opus format
- ML pipeline: VAD → Language Detection → ASR → Diarization → LLM Summary
- Config-driven model swapping
- Speaker renaming post-diarization
- Overview screen with all recordings
- VIPER Architecture: 8 modules, each with Assembly + Interactor + Presenter + Router + View
- VIPER Strictness: View is passive (zero business logic), Interactor holds no state, Router handles navigation
- VIPER Communication: ModuleInput/ModuleOutput protocols for inter-module data passing
- TDD: Every module and service has unit tests
- Human-in-the-loop verification for integration and visual checks

### Must NOT Have (Guardrails)

**VIPER Architecture Violations:**
- **NO business logic in View** — View only renders Presenter state and forwards user actions to Presenter
- **NO direct service access from Presenter** — services accessed only through Interactor
- **NO direct service access from View** — View communicates only with Presenter
- **NO navigation logic in Presenter** — Presenter calls Router methods for all navigation
- **NO state in Interactor** — Interactor holds only dependencies (services + weak output reference)
- **NO framework-specific types crossing Interactor boundary** — Interactor returns plain Swift types, not CoreBluetooth/AVFoundation types
- **NO cross-module direct dependencies** — modules communicate only via ModuleInput/ModuleOutput protocols
- **NO View creating its own Presenter** — Assembly wires the entire module

**Code Quality:**
- **NO print statements** — use OSLog/ScribeLogger throughout
- **NO force unwraps** (`!`) — use guard/let or throw errors
- **NO empty catch blocks** — every catch must handle meaningfully
- **NO files over 400 lines** — split if approaching limit
- **NO magic numbers** — all constants in Config files

**Scope Boundaries:**
- **NO real-time transcription** — post-recording processing only
- **NO recording editing/trimming** — out of scope
- **NO Apple Notes export** — explicitly removed
- **NO file sync from device storage** — out of scope
- **NO cloud sync/sharing** — 100% on-device
- **NO modification of SLink protocol logic** — copy as-is, wrap behind protocols
- **NO BLE characteristic UUID changes** — E49A3001, E49A3003, F0F1-F0F4 are read-only
- **NO Core/Entity layer imports** of SwiftUI, CoreBluetooth, AVFoundation, or any framework

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES (Xcode test target, XCTest)
- **Automated tests**: TDD (RED → GREEN → REFACTOR for every task)
- **Framework**: XCTest (iOS native, Xcode-integrated)
- **Swift Testing framework** (iOS 18+ compatible) where applicable
- **TDD workflow**: Each sub-task creates failing test first, then minimal implementation, then refactor

### Human-in-the-Loop Policy
Human verification is wanted and valued. The user will guide, help, and check throughout.
- **TDD using unit tests** is always the first step for verification
- **Agent-executed QA scenarios** complement but do not replace human verification
- **BLE connection with real hardware** requires human manual verification
- **UI pixel-perfect match** benefits from human visual spot-checks
- **Integration testing** uses agent-executed scenarios with human review of results
- **Final Verification Phase** presents consolidated results to user for explicit approval

### Orchestrator Verification Protocol (MANDATORY)

> **Between EVERY sub-task, the orchestrator MUST verify before proceeding.**

**Verification Steps (after each sub-task):**
1. **Build Check**: Run `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build`
2. **File Existence**: Verify all files listed in the sub-task were created/modified
3. **Line Count**: Verify no file exceeds 400 lines
4. **Quality Scan**: Grep for `print(`, force unwraps `!` (excluding `@IBOutlet`), empty catch blocks
5. **Proceed or Retry**: If all checks pass → move to next sub-task. If any fail → send sub-agent back with error context

**Retry Rules:**
- Maximum 2 retries per sub-task
- If 2 retries fail → mark sub-task as "blocked" and ask user for guidance
- On retry, include the error output and exact failure mode in the sub-agent prompt
- On success, append learnings to `.sisyphus/notepads/scribe-rebuild/learnings.md`

### TDD Agent Workflow Rules
1. **Build command is ALWAYS**: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus'`
2. **Test command is ALWAYS**: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' test`
3. **SourceKit-LSP errors are informational only** — agents must verify with actual xcodebuild, not LSP diagnostics
4. **If xcodebuild succeeds but LSP shows errors** — trust xcodebuild, ignore LSP
5. **If xcodebuild fails** — fix the build error, do not chase LSP ghosts
6. **Each test file must import XCTest** and be part of the ScribeTests target

---

## Execution Strategy

### VIPER Module Structure (Canonical Pattern)

Every VIPER module follows this structure. Each sub-task creating a module must adhere to it:

```
Modules/{ModuleName}/
  Assembly/
    {ModuleName}Assembly.swift      — Creates and wires all module components
  Interactor/
    {ModuleName}Interactor.swift    — Business logic facade over Services
    {ModuleName}InteractorInput.swift   — Protocol: Presenter → Interactor
    {ModuleName}InteractorOutput.swift  — Protocol: Interactor → Presenter
  Presenter/
    {ModuleName}Presenter.swift     — @Observable mediator, holds module state
    {ModuleName}ViewOutput.swift    — Protocol: View → Presenter (user actions)
    {ModuleName}ViewInput.swift     — Protocol: Presenter → View (display updates)
    {ModuleName}ModuleInput.swift   — Protocol: External → Module (configuration)
    {ModuleName}ModuleOutput.swift  — Protocol: Module → External (results)
    {ModuleName}State.swift         — Plain state object (if state is complex)
  Router/
    {ModuleName}Router.swift        — Navigation between modules
    {ModuleName}RouterInput.swift   — Protocol: Presenter → Router
  View/
    {ModuleName}View.swift          — SwiftUI view (passive, renders Presenter state)
    {ModuleName}CellObject.swift    — Cell model for lists (if applicable)
```

**Reference binding conventions:**
- View holds **strong** reference to Presenter (called `output`)
- Presenter holds **weak** reference to View (called `view`)
- Presenter holds **strong** reference to Interactor (called `interactor`)
- Presenter holds **strong** reference to Router (called `router`)
- Interactor holds **weak** reference to Presenter (called `output`)
- Interactor holds **strong** references to Services

**Method naming conventions:**
- Action methods (imperative): `obtainRecordings()`, `processRecording()`, `startScan()`
- Completion methods (did prefix): `didObtainRecordings()`, `didProcessRecording()`, `didFailWithError()`
- Router methods: `openRecordingDetail()`, `closeCurrentModule()`, `embedWaveformPlayback()`

### Strict Serial Execution

> **CRITICAL: All sub-tasks execute ONE AT A TIME. No parallelism.**
> After each sub-task completes, the orchestrator verifies build + file existence before proceeding.
> If verification fails, the orchestrator retries (max 2) before escalating to user.

```
Phase 1 — Foundation (~22 sub-tasks, serial):
  1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6  (Project scaffolding)
  2.1 → 2.2 → 2.3 → 2.4 → 2.5          (Config layer)
  3.1 → 3.2 → 3.3 → 3.4 → 3.5          (Infrastructure)
  4.1 → 4.2 → 4.3 → 4.4 → 4.5          (Core entities)
  5.1 → 5.2 → 5.3                       (Core protocols)
  6.1 → 6.2 → 6.3                       (Shared UI)
  7.1 → 7.2 → 7.3                       (AppAssembly skeleton)

Phase 2 — BLE + Audio Services (~18 sub-tasks, serial):
  8.1 → 8.2 → 8.3     (SLink protocol)
  9.1 → 9.2 → 9.3     (Device scanner)
  10.1 → 10.2 → 10.3 → 10.4 → 10.5  (Connection manager)
  11.1 → 11.2 → 11.3  (Audio stream receiver)
  12.1 → 12.2 → 12.3  (Internal mic recorder)
  13.1 → 13.2 → 13.3  (Unified recorder)
  14.1 → 14.2 → 14.3  (Player + waveform)
  15.1 → 15.2          (Recording repository)

Phase 3 — ML Services (~11 sub-tasks, serial):
  16.1 → 16.2   (VAD)
  17.1 → 17.2   (Language detector)
  18.1 → 18.2 → 18.3  (Swiss German ASR)
  19.1 → 19.2   (Diarization)
  20.1 → 20.2 → 20.3 → 20.4  (LLM + Pipeline)

Phase 4 — VIPER Module Stacks (~32 sub-tasks, serial):
  21.1 → 21.2 → 21.3 → 21.4  (RecordingList)
  22.1 → 22.2 → 22.3 → 22.4  (RecordingDetail)
  23.1 → 23.2 → 23.3 → 23.4  (WaveformPlayback)
  24.1 → 24.2 → 24.3 → 24.4  (Transcript)
  25.1 → 25.2 → 25.3 → 25.4  (Summary)
  26.1 → 26.2 → 26.3 → 26.4  (MindMap)
  27.1 → 27.2 → 27.3 → 27.4  (AgentGenerating)
  28.1 → 28.2 → 28.3 → 28.4  (DeviceSettings)

Phase 5 — Views (~12 sub-tasks, serial):
  29.1 → 29.2 → 29.3  (RecordingList views)
  30.1 → 30.2          (RecordingDetail + Waveform views)
  31.1 → 31.2          (Transcript + Summary views)
  32.1                  (MindMap view)
  33.1                  (AgentGenerating view)
  34.1 → 34.2          (DeviceSettings views)

Phase 6 — App Wiring + Integration (~6 sub-tasks, serial):
  35.1 → 35.2 → 35.3  (App wiring)
  36.1 → 36.2          (Integration tests)
  37.1                  (Documentation)

Phase FINAL — Verification (4 reviews, then user okay):
  F1 → F2 → F3 → F4 → Present results → Get explicit user okay
```

### Sub-Task Format

Every sub-task follows this exact format:

```
- [ ] N.M. Sub-Task Title

  **Files**: exact/file/path1.swift, exact/file/path2.swift
  **Category**: quick | unspecified-low | unspecified-high | visual-engineering | writing
  **Verify**: `xcodebuild ... build` (or specific test command)

  **What**: 2-5 sentences max. What to create/modify, key details.

  **Key Code**: Protocol signatures, struct outlines, method signatures — enough for a local model to implement without guessing.

  **Must NOT**: 1-3 bullet points of explicit guardrails.
```

### Dependency Matrix (Sub-Tasks)

> Sub-tasks within a phase execute serially. Phase N only starts after Phase N-1 completes and orchestrator verifies build success.

| Phase | Sub-Tasks | Blocked By |
|-------|-----------|------------|
| 1 | 1.1–7.3 | None |
| 2 | 8.1–15.2 | Phase 1 complete |
| 3 | 16.1–20.4 | Phase 2 complete |
| 4 | 21.1–28.4 | Phase 3 complete |
| 5 | 29.1–34.2 | Phase 4 complete |
| 6 | 35.1–37.1 | Phase 5 complete |
| FINAL | F1–F4 | Phase 6 complete |

---

## Current Codebase Reference (Embedded for Self-Contained Execution)

> **CRITICAL**: This plan runs in an EMPTY directory with NO existing files.
> All reference code below is from the current Scribe codebase and must be used by
> executing agents to create the new VIPER-architected app from scratch.

### Current Directory Structure (for reference only — DO NOT recreate this nesting)
```
Scribe/Scribe/ScribeApp.swift
Scribe/Scribe/Sources/Audio/AudioRecorder.swift
Scribe/Scribe/Sources/Audio/AudioPlayer.swift
Scribe/Scribe/Sources/Audio/AudioConverter.swift
Scribe/Scribe/Sources/Audio/WaveformAnalyzer.swift
Scribe/Scribe/Sources/Audio/UnifiedRecorder.swift
Scribe/Scribe/Sources/Audio/RecordingsStorage.swift
Scribe/Scribe/Sources/Bluetooth/SLinkProtocol.swift
Scribe/Scribe/Sources/Bluetooth/DeviceConnectionManager.swift
Scribe/Scribe/Sources/Bluetooth/AudioStreamReceiver.swift
Scribe/Scribe/Sources/Bluetooth/BluetoothDevice.swift
Scribe/Scribe/Sources/ML/InferencePipeline.swift
Scribe/Scribe/Sources/ML/LLMService.swift
Scribe/Scribe/Sources/Models/Recording.swift
Scribe/Scribe/Sources/UI/Theme.swift
Scribe/Scribe/Sources/UI/RecordingListView.swift
Scribe/Scribe/Sources/UI/RecordingDetailView.swift
Scribe/Scribe/Sources/UI/RecordingCardView.swift
Scribe/Scribe/Sources/UI/RecordButtonView.swift
Scribe/Scribe/Sources/UI/AgentGeneratingView.swift
Scribe/Scribe/Sources/UI/DashboardHeaderView.swift
Scribe/Scribe/Sources/UI/DeviceSettingsView.swift
Scribe/ScribeTests/Bluetooth/BluetoothDeviceTests.swift
```

### Key Constants from Current Codebase (MUST be preserved exactly)

<details>
<summary><b>BLE SLink UUIDs (from DeviceConnectionManager.swift)</b></summary>

```swift
enum DVRLinkUUID {
    static let primaryService            = CBUUID(string: "E49A3001-F69A-11E8-8EB2-F2801F1B9FD1")
    static let commandWriteChar          = CBUUID(string: "F0F1")
    static let fileTransferCharacteristic = CBUUID(string: "F0F2")
    static let fileTransferChar2          = CBUUID(string: "F0F3")
    static let fileTransferChar3          = CBUUID(string: "F0F4")
    static let audioStreamCharacteristic = CBUUID(string: "E49A3003-F69A-11E8-8EB2-F2801F1B9FD1")
    static let batteryService            = CBUUID(string: "180F")
    static let batteryCharacteristic     = CBUUID(string: "2A19")
}
```

</details>

<details>
<summary><b>SLink Protocol Constants (from SLinkProtocol.swift)</b></summary>

```swift
public enum SLinkConstants {
    public static let headerBytes: [UInt8] = [0x80, 0x08]
    public static let protocolFamily = "DVR_SLink"
    public static let defaultTimeout: TimeInterval = 5.0
    public static let commandDelay: TimeInterval = 0.1
    public static let maxPayloadSize = 128
}

public enum SLinkCommand: UInt16, CaseIterable, Sendable {
    case handshake = 0x0202
    case sendSerial = 0x0203
    case getDeviceInfo = 0x0201
    case configure = 0x0204
    case statusControl = 0x0205
    case command18 = 0x0218
    case command0A = 0x020A
    case command17 = 0x0217
}

public enum SLinkConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case handshaking
    case sendingSerial
    case gettingDeviceInfo
    case configuring
    case statusControl
    case initializing
    case initialized
    case bound
    case syncing
    case recording
    case failed(String)
}

// Checksum: XOR 0x5F00 mask algorithm
public enum SLinkChecksum {
    public static func calculate(for command: UInt16, length: UInt8, payload: [UInt8]) -> UInt16 {
        var data: [UInt8] = []
        data.append(UInt8((command >> 8) & 0xFF))
        data.append(UInt8(command & 0xFF))
        data.append(length)
        data.append(contentsOf: payload)
        var sum: UInt16 = 0
        for (index, byte) in data.enumerated() {
            if index % 2 == 0 {
                sum = sum &+ (UInt16(byte) << 8)
            } else {
                sum = sum &+ UInt16(byte)
            }
        }
        let xorMask: UInt16 = 0x5F00
        return sum ^ xorMask
    }
}

// 8-step init sequence
public struct SLinkInitSequence {
    public static let commands: [SLinkCommand] = [
        .handshake, .sendSerial, .getDeviceInfo, .configure,
        .statusControl, .command18, .command0A, .command17
    ]
    public static let commandDelay: TimeInterval = 0.1
}

// Device serial hardcoded
private let deviceSerial = "129950"

// Configure payload
case .configure: return [0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32]
```

</details>

<details>
<summary><b>Connection Manager Constants (from DeviceConnectionManager.swift)</b></summary>

```swift
// Connection timeout
private let connectionTimeoutSeconds: TimeInterval = 10
private let maxReconnectAttempts = 5
private let userDefaultsKey = "lastConnectedDeviceID"

// Keep-alive heartbeat interval
Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true)

// Known device names
private let knownDeviceNames: Set<String> = [
    "LA518", "LA519", "L027", "L813", "L815", "L816", "L817", "MAR-2518",
    "19CAEEngine_2MicPhone", "MlpAES2MicTV"
]
private let rssiThreshold: Int = -70

// Notification names
extension Notification.Name {
    static let audioCharacteristicDidUpdate = Notification.Name("com.scribe.audioCharacteristicDidUpdate")
    static let connectionStateDidChange = Notification.Name("com.scribe.connectionStateDidChange")
}
```

</details>

<details>
<summary><b>Theme Constants (from Theme.swift)</b></summary>

```swift
struct Theme {
    static let obsidian = Color(red: 0.1, green: 0.1, blue: 0.11)
    static let cardBackgroundLight = Color.white
    static let cardBackgroundDark = Color(red: 0.15, green: 0.15, blue: 0.16)
    static let scribeRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let accentGray = Color.gray.opacity(0.3)
    static let cornerRadius: CGFloat = 20.0
    static let shadowRadius: CGFloat = 10.0
    static let shadowOpacityLight: Double = 0.05
    static let shadowOpacityDark: Double = 0.2
}

// scribeCardStyle ViewModifier
func scribeCardStyle(scheme: ColorScheme) -> some View {
    self
        .padding()
        .background(Theme.cardBackground(for: scheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(scheme == .dark ? Theme.shadowOpacityDark : Theme.shadowOpacityLight),
                radius: Theme.shadowRadius, x: 0, y: 4)
}
```

</details>

<details>
<summary><b>ML Pipeline Constants (from InferencePipeline.swift + LLMService.swift)</b></summary>

```swift
// Diarization
var config = OfflineDiarizerConfig(clusteringThreshold: 0.35)
config = config.withSpeakers(min: 1, max: 8)

// Transcription: minimum 8000 samples (0.5 sec at 16kHz)
guard samples.count > 8000 else { return "" }

// LLM
private static let singlePassThreshold = 25_000
private static let chunkSize = 12_000
private static let chunkOverlap = 1_200
private static let modelFileName = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
private static let modelDownloadURL = URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf")!

// Swiss German Whisper
// URL: jlnslv/whisper-large-v3-turbo-swiss-german-coreml

// Custom Llama 3 chat template
private static let llama3Template = Template(
    system: ("<|start_header_id|>system<|end_header_id|>\n\n", "<|eot_id|>"),
    user:   ("<|start_header_id|>user<|end_header_id|>\n\n",   "<|eot_id|>"),
    bot:    ("<|start_header_id|>assistant<|end_header_id|>\n\n", "<|eot_id|>"),
    stopSequence: "<|eot_id|>",
    systemPrompt: nil
)
```

</details>

<details>
<summary><b>Audio Config Constants (from AudioRecorder.swift + UnifiedRecorder.swift)</b></summary>

```swift
// Internal mic recording format
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 48000,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]
// File format: .m4a (will change to .caf/Opus in rebuild)

// BLE audio: Float32 PCM at 16kHz, frame size 320 samples (20ms)
// CAF file format for BLE audio
// Opus decoding via swift-opus (Opus.Decoder)

// AudioConverter: CAF parser, Float32 PCM extraction
// WaveformAnalyzer: 50 bars, peak-per-bin, normalize to [0.05, 1.0]

// Playback: AVAudioPlayer
// Speed cycling: 1.0x → 1.5x → 2.0x → 1.0x
// Skip: ±15 seconds
```

</details>

<details>
<summary><b>Recording Model (from Recording.swift)</b></summary>

```swift
@Model
final class Recording {
    @Attribute(.unique) var id: String
    var title: String
    var createdAt: Date
    var duration: TimeInterval
    var audioFilePath: String
    var categoryTag: String
    var rawTranscript: String?
    var meetingNotes: String?
    var actionItems: String?
    var mindMapJSON: Data?
    
    init(id: String = UUID().uuidString, title: String, createdAt: Date = Date(),
         duration: TimeInterval = 0.0, audioFilePath: String, categoryTag: String = "#NOTE") {
        self.id = id; self.title = title; self.createdAt = createdAt
        self.duration = duration; self.audioFilePath = audioFilePath; self.categoryTag = categoryTag
    }
}
```

</details>

<details>
<summary><b>UI Layout Reference (key dimensions from current views)</b></summary>

```
RecordButtonView: outer 80x80 circle, inner 70x70 circle
  - Outer: scribeRed.opacity(0.3), scaleEffect 1.5x when recording
  - Inner: scribeRed (0.8 opacity), shadow radius 10
  - Recording: 24x24 white stop icon; Idle: mic.fill (28pt bold white)
  - Animation: easeInOut duration 1.5s repeatForever when recording
  - Disabled: opacity 0.5

WaveformView: 50 bars, spacing 3pt, corner radius 2pt, min height 4pt
  - Played: scribeRed, Unplayed: secondary.opacity(0.3)

Playback controls: skipBackward(15s), play/pause (44pt scribeRed), skipForward(15s)
  - Speed capsule: 44pt wide, background secondary.opacity(0.15)
  - Speed cycle: 1.0x → 1.5x → 2.0x → 1.0x

AgentGeneratingView (iOS 18+):
  - MeshGradient 3x3 with black, scribeRed, indigo
  - Pulsating circles: 140pt/100pt/80pt with waveform.circle.fill
  - "ARTIFICIAL INTELLIGENCE" text (headline, white 0.7)
  - Progress bar: 250x6pt capsule, white fill
  - Animations: mesh 4.0s easeInOut repeatForever, circle pulse 1.5s

DeviceSettingsView:
  - ConnectionStatusCard (scribeCardStyle)
  - Connection states: connected/green, connecting/yellow, failed/scribeRed, disconnected/secondary
  - DeviceRow: mic icon, name, RSSI badge, battery, chevron
  - Scan timeout: 10 seconds
  - Supported devices footer: "LA518, LA519, L027, L813–L817, MAR-2518"

RecordingListView:
  - NavigationStack, PlainListStyle
  - DashboardHeaderView (placeholder)
  - Empty state: mic.slash icon, "No recordings yet."
  - Mic indicator badge at bottom
  - RecordButtonView at bottom center
  - Delete via .onDelete

RecordingDetailView:
  - Top: waveform + playback controls in scribeCardStyle
  - Bottom: segmented picker (Summary|Transcript|Mind Map)
  - Floating CTA: "Generate Transcript" (red capsule) when no transcript
  - Speaker rename: alert with text field
```

</details>

---

## TODOs

> **IMPORTANT**: This plan runs in an EMPTY directory with NO existing source files.
> All code must be created from scratch. The "Current Codebase Reference" section above
> contains all critical constants, algorithms, and UI specifications needed.
>
> **iOS Deployment Target**: IPHONEOS_DEPLOYMENT_TARGET = 18.0
> **Scheme Name**: Scribe
> **Bundle Identifier**: com.scribe.app

### Phase 1 — Foundation

- [x] 1.1. Create Xcode Project + VIPER Directory Structure

  **Files**: Scribe.xcodeproj/project.pbxproj, Scribe/ScribeApp.swift, Scribe/Info.plist, ScribeTests/Info.plist, .gitkeep files in all directories
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build`

  **What**: Create the Xcode project at root level (NOT nested like the old triple Scribe/Scribe/Scribe structure). Single target "Scribe" with IPHONEOS_DEPLOYMENT_TARGET = 18.0. Create ALL VIPER directories with .gitkeep placeholder files. Create ScribeTests target.

  **Key Code**:
  ```swift
  // Scribe/ScribeApp.swift
  import SwiftUI
  import SwiftData

  @main
  struct ScribeApp: App {
      var body: some Scene {
          WindowGroup {
              Text("Scribe — Loading...")
                  .preferredColorScheme(.dark)
          }
          .modelContainer(for: Recording.self)
      }
  }
  ```

  **CRITICAL**: This plan runs in an EMPTY directory. There are NO existing source files. Create everything from scratch.

  **Directory Structure** (create .gitkeep in each):
  ```
  Scribe/
  ├── ScribeApp.swift
  ├── Info.plist
  ├── Core/
  │   ├── Config/
  │   ├── Entities/
  │   ├── Protocols/
  │   └── Infrastructure/
  │       ├── Extensions/
  │       ├── Logging/
  │       └── Persistence/
  ├── Services/
  │   ├── BLEService/
  │   │   └── SLink/
  │   ├── AudioService/
  │   ├── MLService/
  │   │   ├── VAD/
  │   │   ├── ASR/
  │   │   ├── Diarization/
  │   │   ├── Summarization/
  │   │   └── Pipeline/
  │   └── RecordingService/
  ├── Modules/
  │   ├── RecordingListModule/
  │   │   ├── Assembly/
  │   │   ├── Interactor/
  │   │   ├── Presenter/
  │   │   ├── Router/
  │   │   └── View/
  │   ├── RecordingDetailModule/ (same structure + Router)
  │   ├── WaveformPlaybackModule/ (no Router - embedded)
  │   ├── TranscriptModule/ (no Router - embedded)
  │   ├── SummaryModule/ (no Router - embedded)
  │   ├── MindMapModule/ (no Router - embedded)
  │   ├── AgentGeneratingModule/ (no Router - presented modally)
  │   └── DeviceSettingsModule/ (same structure + Router)
  ├── SharedUI/
  │   └── Theme/
  └── App/
  ScribeTests/
  ├── App/
  ├── Config/
  ├── Entities/
  ├── Infrastructure/
  ├── Modules/ (one dir per module)
  ├── Protocols/
  ├── Services/ (BLE, Audio, ML, Recording)
  └── SharedUI/
  ```

  **Must NOT**: Do NOT create multiple targets or SPM packages. Do NOT implement any features — scaffolding only. Do NOT create the old triple-nested Scribe/Scribe/Scribe structure.

- [x] 1.2. Add SPM Dependencies

  **Files**: Scribe.xcodeproj/project.pbxproj (update package references)
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build` (dependencies must resolve)

  **What**: Add 6 SPM dependencies to the Xcode project:
  1. FluidAudio: https://github.com/FL33TW00D/FluidAudio (for Parakeet ASR, OfflineDiarizer, VAD)
  2. llama.cpp: https://github.com/ggerganov/llama.cpp (for LLM inference via LLM.swift)
  3. swift-huggingface: https://github.com/huggingface/swift-huggingface (for model downloading)
  4. swift-transformers: https://github.com/huggingface/swift-transformers (for CoreML model loading)
  5. swift-opus: https://github.com/GeorgeLyon/swift-opus (for Opus audio codec)
  6. yyjson (for JSON parsing performance)

  **Must NOT**: Do NOT add dependencies beyond the 6 listed. Do NOT create a separate Package.swift — add as Xcode project package dependencies.

- [ ] 1.3. Create First Test + Verify Build

  **Files**: ScribeTests/App/ScribeAppTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' test`

  **What**: Create a basic test that verifies the app entry point exists and ModelContainer initializes. Run the test suite to confirm the test target works.

  **Key Code**:
  ```swift
  import XCTest
  import SwiftData
  @testable import Scribe

  final class ScribeAppTests: XCTestCase {
      func testAppEntryPointExists() {
          let app = ScribeApp()
          XCTAssertNotNil(app)
      }
  }
  ```

  **Must NOT**: Do NOT write production feature tests — just verify the skeleton compiles and test target runs.

- [x] 2.1. Create PipelineConfig.swift

  **Files**: Core/Config/PipelineConfig.swift, ScribeTests/Config/ConfigTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/ConfigTests`

  **What**: Create PipelineConfig with all ML pipeline constants from the embedded reference. All properties are `let` (immutable). Write tests verifying values are accessible and non-nil.

  **Key Code** (reference: InferencePipeline.swift, LLMService.swift):
  ```swift
  struct PipelineConfig: Sendable {
      let swissGermanWhisperURL = "jlnslv/whisper-large-v3-turbo-swiss-german-coreml"
      let diarizationClusteringThreshold: Double = 0.35
      let minSpeakers: Int = 1
      let maxSpeakers: Int = 8
      let singlePassThreshold: Int = 25_000
      let chunkSize: Int = 12_000
      let chunkOverlap: Int = 1_200
      let llmModelFileName = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
      let llmModelDownloadURL = "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
      let stageTimeout: TimeInterval = 60
      let minASRSamples: Int = 8000  // 0.5 sec at 16kHz
  }
  ```

  **Must NOT**: Do NOT implement business logic. Do NOT use UserDefaults or dynamic loading.

- [x] 2.2. Create AudioConfig.swift

  **Files**: Core/Config/AudioConfig.swift, ScribeTests/Config/ConfigTests.swift (append)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/ConfigTests`

  **What**: Create AudioConfig with unified format constants. Reference: current AudioRecorder uses 48kHz AAC, BLE uses 16kHz Opus. Rebuild uses unified Opus/CAF at 16kHz mono.

  ```swift
  struct AudioConfig: Sendable {
      let sampleRate: Double = 16_000
      let channelCount: Int = 1
      let frameSize: Int = 320  // 20ms at 16kHz
      let fileExtension = "caf"
      let formatHint = "opus"
      let internalMicSampleRate: Double = 48_000
      let internalMicFormat = "m4a"  // fallback for internal mic AAC
  }
  ```

- [x] 2.3. Create BluetoothConfig.swift

  **Files**: Core/Config/BluetoothConfig.swift, ScribeTests/Config/ConfigTests.swift (append)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/ConfigTests`

  **What**: Create BluetoothConfig with all BLE constants. Reference: DVRLinkUUID from DeviceConnectionManager.swift and known device names from BluetoothDeviceScanner.swift (see embedded reference).

  ```swift
  struct BluetoothConfig: Sendable {
      let serviceUUID = "E49A3001-F69A-11E8-8EB2-F2801F1B9FD1"
      let audioCharacteristicUUID = "E49A3003-F69A-11E8-8EB2-F2801F1B9FD1"
      let commandCharacteristicUUID = "F0F1"
      let fileTransferCharacteristicUUID = "F0F2"
      let fileTransferChar2UUID = "F0F3"
      let fileTransferChar3UUID = "F0F4"
      let batteryServiceUUID = "180F"
      let batteryCharacteristicUUID = "2A19"
      let deviceSerial = "129950"
      let connectionTimeout: TimeInterval = 10
      let sLinkTimeout: TimeInterval = 5
      let keepAliveInterval: TimeInterval = 3
      let rssiThreshold: Int = -70
      let maxReconnectAttempts: Int = 5
      let knownDeviceNames = ["LA518", "LA519", "L027", "L813", "L814", "L815", "L816", "L817", "MAR-2518", "19CAEEngine_2MicPhone", "MlpAES2MicTV"]
  }
  ```

  **Must NOT**: Do NOT change BLE characteristic UUIDs. Do NOT modify SLink protocol logic.

- [x] 2.4. Create FeatureFlags.swift

  **Files**: Core/Config/FeatureFlags.swift, ScribeTests/Config/ConfigTests.swift (append)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/ConfigTests`

  **What**: Create FeatureFlags struct with feature toggles: enableVAD (true), enableLanguageDetection (true), enableSwissGermanASR (true), enableDiarization (true), enableSummarization (true), enableBLE (true), enableDebugLogging (false). All `let` properties.

- [x] 3.1. Create ScribeLogger.swift

  **Files**: Core/Infrastructure/Logging/ScribeLogger.swift, ScribeTests/Infrastructure/LoggerTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/LoggerTests`

  **What**: Create ScribeLogger using os.Logger with subsystem "com.scribe.app". Log levels: debug, info, warning, error, fault. Category-based logging: ble, audio, ml, ui, pipeline. Singleton instance `ScribeLogger.shared`. Static convenience methods. This REPLACES all `print()` statements in existing code.

  **Key Code**: See embedded reference — current code has 133 print() calls that must all become ScribeLogger calls.

- [ ] 3.2. Create Extension Files

  **Files**: Core/Infrastructure/Extensions/Date+Formatting.swift, Core/Infrastructure/Extensions/String+Validation.swift, Core/Infrastructure/Extensions/TimeInterval+Formatting.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create three extensions. Reference: RecordingCardView.swift has `formatDuration()` that should be extracted. TimeInterval+Formatting: formatDuration → "1:05" or "1:01:01". String+Validation: isEmptyOrNil, isValidFilename. Date+Formatting: formatted date strings. Write tests for TimeInterval formatting edge cases (0, 65, 3661).

- [ ] 3.3. Create SwiftDataModelContainer.swift

  **Files**: Core/Infrastructure/Persistence/SwiftDataModelContainer.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create SwiftDataModelContainer that sets up ModelContainer for Recording entity. Reference: current ScribeApp.swift has the model container setup. Use on-disk persistence. Provide static `shared` instance for app-wide use. Update ScribeApp.swift to use this container.

  **Key Code** (reference: ScribeApp.swift):
  ```swift
  import SwiftData

  final class SwiftDataModelContainer {
      static let shared: ModelContainer = {
          let schema = Schema([Recording.self])
          let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
          do {
              return try ModelContainer(for: schema, configurations: [config])
          } catch {
              fatalError("Failed to create ModelContainer: \(error)")
          }
      }()
      private init() {}
  }
  ```

- [x] 4.1. Create Recording.swift Entity

  **Files**: Core/Entities/Recording.swift, ScribeTests/Entities/EntityTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/EntityTests`

  **What**: Create SwiftData @Model Recording with all properties from the embedded reference. Add `micSource: String` field (default "internal") for dual-source tracking. Only import Foundation and SwiftData — no SwiftUI, CoreBluetooth, or AVFoundation.

  **Key Code** (reference: Recording.swift in embedded reference):
  ```swift
  import Foundation
  import SwiftData

  @Model
  final class Recording {
      @Attribute(.unique) var id: String
      var title: String
      var createdAt: Date
      var duration: TimeInterval
      var audioFilePath: String
      var categoryTag: String
      var rawTranscript: String?
      var meetingNotes: String?
      var actionItems: String?
      var mindMapJSON: Data?
      var micSource: String

      init(id: String = UUID().uuidString, title: String = "Untitled", createdAt: Date = .now,
           duration: TimeInterval = 0, audioFilePath: String = "", categoryTag: String = "#NOTE",
           rawTranscript: String? = nil, meetingNotes: String? = nil, actionItems: String? = nil,
           mindMapJSON: Data? = nil, micSource: String = "internal") { ... }
  }
  ```

- [x] 4.2. Create Transcript.swift and SpeakerSegment

  **Files**: Core/Entities/Transcript.swift, ScribeTests/Entities/EntityTests.swift (append)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/EntityTests`

  **What**: Create SpeakerSegment struct (speakerId: String, start: TimeInterval, end: TimeInterval, text: String) and Transcript struct (segments: [SpeakerSegment]). Both Codable and Equatable. Only import Foundation.

- [x] 4.3. Create MeetingSummary.swift and TopicSection

  **Files**: Core/Entities/MeetingSummary.swift, ScribeTests/Entities/EntityTests.swift (append)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/EntityTests`

  **What**: Create MeetingSummary struct (title: String, meetingNotes: [TopicSection], actionItems: String, mindMapNodes: [MindMapNode]) and TopicSection struct (topic: String, bullets: [String]). Reference: LLMService.swift in embedded reference. Both Codable. Write test verifying JSON round-trip encoding/decoding.

- [x] 4.4. Create MindMapNode.swift, AudioSample.swift, RecordingSource.swift

  **Files**: Core/Entities/MindMapNode.swift, Core/Entities/AudioSample.swift, Core/Entities/RecordingSource.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create MindMapNode (recursive Codable: id, text, children: [MindMapNode]). Reference: LLMService.swift MindMapNode struct. Create AudioSample (value: Float, timestamp: TimeInterval). Create RecordingSource enum (case internal, ble). All Codable. Write encoding/decoding tests for MindMapNode recursive structure.

- [x] 5.1. Create ServiceProtocols.swift

  **Files**: Core/Protocols/ServiceProtocols.swift, ScribeTests/Protocols/ServiceProtocolMocks.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all service protocol definitions in one file. Reference: current codebase uses InferencePipeline, AudioRecorder, AudioPlayer, etc. Protocols: AudioRecorderProtocol, AudioPlayerProtocol, DiarizationServiceProtocol, TranscriptionServiceProtocol, SummarizationServiceProtocol, VADServiceProtocol, LanguageDetectionProtocol, BluetoothDeviceScannerProtocol, AudioStreamProtocol, RecordingRepositoryProtocol. Include LanguageConfidence { language, confidence, isSwissGerman }. Include mock implementations in test target. Only import Foundation.

  **Key Code**: See original plan task 5.1 for full protocol signatures.

- [x] 5.2. Create VIPERProtocols.swift

  **Files**: Core/Protocols/VIPERProtocols.swift, ScribeTests/Protocols/VIPERProtocolTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create VIPER base protocols: ModuleInput (base for module configuration), ModuleOutput (base for module results with associatedtype OutputType), AssemblyProtocol (base for module factories with associatedtype ViewType). Write tests verifying protocol conformance compiles.

- [ ] 6.1. Create Theme.swift

  **Files**: SharedUI/Theme/Theme.swift, ScribeTests/SharedUI/ThemeTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/ThemeTests`

  **What**: Create Theme with EXACT current design tokens from embedded reference. scribeRed, obsidian, cardBackgroundLight/Dark, accentGray, cornerRadius 20pt, shadowRadius 10pt, shadowOpacityLight/Dark. .scribeCardStyle(scheme:) view modifier. Force dark mode. Write tests verifying color values match.

  **Key Code** (reference: Theme.swift in embedded reference — MUST match exactly):
  ```swift
  struct Theme {
      static let scribeRed = Color(red: 0.9, green: 0.2, blue: 0.2)
      static let obsidian = Color(red: 0.1, green: 0.1, blue: 0.11)
      static let cardBackgroundLight = Color.white
      static let cardBackgroundDark = Color(red: 0.15, green: 0.15, blue: 0.16)
      static let accentGray = Color.gray.opacity(0.3)
      static let cornerRadius: CGFloat = 20.0
      static let shadowRadius: CGFloat = 10.0
      static let shadowOpacityLight: Double = 0.05
      static let shadowOpacityDark: Double = 0.2
  }
  ```

  **Must NOT**: Do NOT change ANY color values — exact match required.

- [ ] 6.2. Create Spacing.swift + Typography.swift

  **Files**: SharedUI/Theme/Spacing.swift, SharedUI/Theme/Typography.swift, ScribeTests/SharedUI/ThemeTests.swift (append)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/ThemeTests`

  **What**: Create Spacing with all hardcoded UI values from current views. Reference: RecordButtonView (80x80, 70x70 outer/inner circles), WaveformView (50 bars, 3pt spacing, 2pt corner radius, 4pt min height), skip buttons (15s), playback button (44pt scribeRed), dashboard padding etc. Create Typography with system font styles.

- [ ] 7.1. Create ServiceRegistry.swift

  **Files**: App/ServiceRegistry.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create ServiceRegistry that holds all service protocol references as stubs (placeholder implementations that compile but crash with fatalError("Not implemented") when called). BleService, AudioService, MLService, RecordingService categories. Each service stored as its protocol type.

  **Must NOT**: Do NOT implement any service — only register placeholder types. Do NOT use global singletons outside ServiceRegistry.

- [ ] 7.2. Create AppAssembly.swift

  **Files**: App/AppAssembly.swift, ScribeTests/App/AppAssemblyTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/AppAssemblyTests`

  **What**: Create AppAssembly that wires all service stubs from ServiceRegistry and has factory methods for each of the 8 modules (returns placeholder Views for now). Update ScribeApp.swift to use AppAssembly. Write test verifying assembly creates all components.

- [ ] 7.3. Verify Phase 1 — Full Build

  **Files**: None (verification only)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build && xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' test`

  **What**: Run full build and test suite. Verify all Phase 1 files compile, all tests pass, zero print statements, zero force unwraps, zero empty catch blocks. Save build output to .sisyphus/evidence/phase1-build.txt and test output to .sisyphus/evidence/phase1-tests.txt.

  **Must NOT**: Do NOT modify any code in this sub-task — only verify and report.

### Phase 2 — BLE + Audio Services

- [ ] 8.1. Create SLinkConstants, SLinkCommand, SLinkConnectionState

  **Files**: Services/BLEService/SLink/SLinkConstants.swift, Services/BLEService/SLink/SLinkCommand.swift, Services/BLEService/SLink/SLinkConnectionState.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Extract constants from the embedded reference SLinkProtocol.swift. Create SLinkCommand enum with all 8 commands (0x0202, 0x0203, 0x0201, 0x0204, 0x0205, 0x0218, 0x020A, 0x0217) with defaultPayload for each (especially configure: [0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32] and sendSerial: "129950" padded to 17 bytes). Create SLinkConnectionState enum with 12 states (disconnected, connecting, handshaking, sendingSerial, gettingDeviceInfo, configuring, statusControl, initializing, initialized, bound, syncing, recording, failed). Reference: embedded reference SLinkProtocol.swift for exact values.

  **Must NOT**: Do NOT modify any SLink protocol logic — copy values as-is from the embedded reference.

- [ ] 8.2. Create SLinkProtocol.swift and SLinkPacketParser.swift

  **Files**: Services/BLEService/SLink/SLinkProtocol.swift, Services/BLEService/SLink/SLinkPacketParser.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Recreate SLink protocol logic from the embedded reference. SLinkProtocol.swift: SLinkPacket struct with header (0x80 0x08), command, length, payload, checksum, serialize(). SLinkPacketParser.swift: stateful buffer parser that finds header bytes [0x80, 0x08], parses command/length/payload/checksum, validates with SLinkChecksum (XOR 0x5F00 mask). Wrap behind AudioStreamProtocol from Core/Protocols. Reference: embedded reference has the EXACT packet format, checksum algorithm, and parser logic — reproduce faithfully.

  **Must NOT**: Do NOT modify SLink protocol logic. Do NOT change BLE characteristic UUIDs. Do NOT change 8-step init sequence.

- [ ] 8.3. Create SLink Tests

  **Files**: ScribeTests/Services/BLE/SLinkPacketParserTests.swift, ScribeTests/Services/BLE/SLinkChecksumTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/SLinkPacketParserTests`

  **What**: Write tests for packet parsing (feed raw Data) and checksum validation (known input → known output from the XOR 0x5F00 algorithm). Verify the checksum for handshake command (0x0202 with empty payload) matches expected output. Verify parsing matches current behavior.

- [ ] 9.1. Create BluetoothDevice.swift

  **Files**: Services/BLEService/BluetoothDevice.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create BluetoothDevice value type. Reference: embedded reference BluetoothDevice.swift has id (String), name (String), rssi (Int), isConnected (Bool), batteryLevel (Int?). Conforms to Identifiable, Equatable. ALSO create ScannerConnectionDelegate protocol with scannerDidConnect, scannerDidFailToConnect, scannerDidDisconnect methods (from the embedded reference).

- [ ] 9.2. Create BluetoothDeviceScanner.swift

  **Files**: Services/BLEService/BluetoothDeviceScanner.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create BluetoothDeviceScanner implementing BluetoothDeviceScannerProtocol. Reference: embedded reference BluetoothDeviceScanner.swift wraps CBCentralManager. Filters by known device names from BluetoothConfig and RSSI threshold (-70 dBm). Scan timeout from BluetoothConfig. Replace ALL print statements with ScribeLogger.

  **Must NOT**: Do NOT modify SLink protocol logic. Do NOT use print statements.

- [ ] 9.3. Create BluetoothDeviceScanner Tests

  **Files**: ScribeTests/Services/BLE/BluetoothDeviceScannerTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/BluetoothDeviceScannerTests`

  **What**: Write tests with MockCBCentralManager: verify "LA518" with RSSI -65 is included, "Unknown" is excluded, "LA518" with RSSI -80 is excluded (below threshold).

- [x] 10.1. Create ConnectionStateMachine.swift

  **Files**: Services/BLEService/ConnectionStateMachine.swift, ScribeTests/Services/BLE/ConnectionStateMachineTests.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/ConnectionStateMachineTests`

  **What**: Create ConnectionStateMachine enum with states matching the SLink init sequence. Reference: embedded reference DeviceConnectionManager.swift has ConnectionState enum with 9 cases (disconnected, connecting, connected, binding, initializing, initialized, bound, failed(String), reconnecting(Int)). Add transitions and max reconnection attempts (5 from BluetoothConfig). Write tests for all transitions and error handling.

- [x] 10.2. Create SLinkInitOrchestrator.swift

  **Files**: Services/BLEService/SLinkInitOrchestrator.swift, ScribeTests/Services/BLE/SLinkInitOrchestratorTests.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/SLinkInitOrchestratorTests`

  **What**: Create SLinkInitOrchestrator that executes the 8-step init sequence. Reference: embedded reference DeviceConnectionManager.swift shows the exact sequence: handshake → sendSerial ("129950") → getDeviceInfo → configure ([0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32]) → statusControl → command18 ([0x01]) → command0A → command17 ([0x00]). Timeout per step from BluetoothConfig.sLinkTimeout (5s). Command delay 0.1s from SLinkConstants. Write tests with mocked protocol verifying each step called in sequence and timeout triggers error.

  **Must NOT**: Do NOT modify SLink protocol logic.

- [ ] 10.3. Create KeepAliveService.swift and DeviceConnectionManager.swift

  **Files**: Services/BLEService/KeepAliveService.swift, Services/BLEService/DeviceConnectionManager.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create KeepAliveService (heartbeat every 3.0s, reference: DeviceConnectionManager.swift line 575). Create DeviceConnectionManager that coordinates scanner, connection state machine, SLink init, and keep-alive. Connection lifecycle: scan → connect → init → keep-alive → disconnect. Reference: embedded reference DeviceConnectionManager.swift is 676 lines — split this into focused components. Connection timeout 10s, max reconnect 5, last connected device ID in UserDefaults. Replace ALL print statements with ScribeLogger.

  **Must NOT**: Do NOT create a single 676-line god class. Do NOT use print statements.

- [ ] 10.4. Create DeviceConnectionManager Tests

  **Files**: ScribeTests/Services/BLE/DeviceConnectionManagerTests.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/DeviceConnectionManagerTests`

  **What**: Write tests with mocked CoreBluetooth: verify scan → connect → init → keep-alive → disconnect lifecycle. Test reconnection (max 5 attempts). Test connection timeout.

- [ ] 10.5. Verify BLE Services Build

  **Files**: None (verification only)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build && xcodebuild -scheme Scribe test`

  **What**: Full build and test verification for all BLE services. Check zero print statements, zero force unwraps, zero empty catch blocks in Services/BLEService/. Save evidence.

- [x] 11.1. Create OpusAudioDecoder.swift

  **Files**: Services/AudioService/OpusAudioDecoder.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create OpusAudioDecoder wrapping swift-opus. Reference: embedded reference AudioStreamReceiver.swift has OpusAudioDecoder class (lines 233-320) that decodes Opus packets to Float32 PCM at 16kHz mono. Handles Opus header stripping (0xFF 0xF3 0x48 0xC4 and 0xFF 0xF3 prefixes). Frame size: 320 samples (20ms at 16kHz) from AudioConfig. IMPORTANT: The current code has header stripping logic that must be preserved exactly.

  **Must NOT**: Do NOT implement custom codec — use swift-opus library.

- [x] 11.2. Create AudioStreamReceiver.swift

  **Files**: Services/AudioService/AudioStreamReceiver.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create AudioStreamReceiver implementing AudioStreamProtocol. Reference: embedded reference AudioStreamReceiver.swift subscribes to audio characteristic (E49A3003). Uses CircularAudioBuffer (max 200 frames). Feeds data through NotificationCenter named .audioCharacteristicDidUpdate. Replace ALL print statements with ScribeLogger.

  **Must NOT**: Do NOT modify Opus decoding logic. Do NOT use print statements.

- [ ] 11.3. Create Opus Decoder Tests

  **Files**: ScribeTests/Services/Audio/OpusAudioDecoderTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/OpusAudioDecoderTests`

  **What**: Test Opus header stripping: 0xFF 0xF3 0x48 0xC4 prefix and 0xFF 0xF3 prefix. Test decoding produces Float32 output at 16kHz.

- [x] 12.1. Create OpusEncoder.swift

  **Files**: Services/AudioService/OpusEncoder.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create OpusEncoder that encodes Float32 PCM to Opus packets using swift-opus library. Frame size: 320 samples at 16kHz mono from AudioConfig.

  **Must NOT**: Do NOT implement custom codec.

- [x] 12.2. Create InternalMicRecorder.swift

  **Files**: Services/AudioService/InternalMicRecorder.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create InternalMicRecorder implementing AudioRecorderProtocol. Reference: embedded reference AudioRecorder.swift. AVAudioEngine-based recording. Session category: .playAndRecord with .allowBluetooth and .defaultToSpeaker. USB-C Plug & Play: listen for AVAudioSession.routeChangeNotification, set preferred input to usbAudio/headsetMic. Haptic feedback on start/stop. Files saved as <UUID>.caf. **CRITICAL BUG FIX**: The current AudioRecorder.swift line 139 has an empty catch block `} catch {}` — this MUST be replaced with ScribeLogger.error.

  **Must NOT**: Do NOT save as .m4a/AAC — must be Opus/CAF. Do NOT use print statements. Do NOT leave empty catch blocks.

- [x] 12.3. Create InternalMicRecorder Tests

  **Files**: ScribeTests/Services/Audio/InternalMicRecorderTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/InternalMicRecorderTests`

  **What**: Test recorder lifecycle (start/stop). Verify no empty catch blocks in Services/AudioService/ (grep).

- [ ] 13.1. Create UnifiedRecorder.swift

  **Files**: Services/AudioService/UnifiedRecorder.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create UnifiedRecorder that orchestrates recording from either source. Reference: embedded reference UnifiedRecorder.swift routes to BLE or internal mic based on connection state. Accepts AudioRecorderProtocol and AudioStreamProtocol via DI. Saves raw Float32 as CAF file. RecordingSource enum for tracking. Replace ALL print statements with ScribeLogger.

  **Must NOT**: Do NOT implement recording logic directly — delegate to internal/BLE recorders.

- [ ] 13.2. Create RecordingOrchestrator.swift

  **Files**: Services/AudioService/RecordingOrchestrator.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create RecordingOrchestrator that manages recording lifecycle. Reference: current UnifiedRecorder.swift handles start, stop, source routing. Move business logic here from the old god class. Handles BLE disconnect mid-recording (falls back to internal or stops cleanly). Replace ALL print statements with ScribeLogger.

- [ ] 13.3. Create UnifiedRecorder Tests

  **Files**: ScribeTests/Services/Audio/UnifiedRecorderTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/UnifiedRecorderTests`

  **What**: Test BLE routing (connected → starts AudioStreamProtocol, disconnected → starts InternalMicRecorder). Test BLE disconnect mid-recording (stops cleanly, saves partial).

- [ ] 14.1. Create AudioPlayer.swift

  **Files**: Services/AudioService/AudioPlayer.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create AudioPlayer implementing AudioPlayerProtocol. Reference: embedded reference AudioPlayer.swift. Wraps AVAudioPlayer with @Observable state. Speed cycling: 1.0x → 1.5x → 2.0x → 1.0x. Skip: ±15 seconds. Seek via progress. Session deactivated on finish/dismiss.

  **Must NOT**: Do NOT implement UI — only audio logic.

- [ ] 14.2. Create WaveformAnalyzer.swift and AudioConverter.swift

  **Files**: Services/AudioService/WaveformAnalyzer.swift, Services/AudioService/AudioConverter.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: WaveformAnalyzer: Reference: embedded reference WaveformAnalyzer.swift uses AVAssetReader, downsamples to 50 bars by peak-per-bin, normalizes to [0.05, 1.0]. AudioConverter: Reference: embedded reference AudioConverter.swift parses CAF files, extracts Float32 PCM data for ASR. Proper error handling (no silent failures).

  **Must NOT**: Do NOT implement custom codecs — use AVAudioConverter or existing libraries.

- [ ] 14.3. Create Audio Player + Waveform Tests

  **Files**: ScribeTests/Services/Audio/AudioPlayerTests.swift, ScribeTests/Services/Audio/WaveformAnalyzerTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/AudioPlayerTests`

  **What**: Test speed cycling (1.0→1.5→2.0→1.0). Test waveform produces 50 normalized bars in [0.05, 1.0]. Test AudioConverter throws on invalid file path.

- [ ] 15.1. Create RecordingRepository.swift

  **Files**: Services/RecordingService/RecordingRepository.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create RecordingRepository implementing RecordingRepositoryProtocol. CRUD methods: save, fetchAll, update, delete. Uses SwiftData ModelContext. Proper error handling (throw, don't swallow). Reference: current RecordingListView.swift shows how recordings are saved/fetched.

  **Must NOT**: Do NOT add business logic — pure data access only. Do NOT use print statements.

- [ ] 15.2. Create RecordingRepository Tests

  **Files**: ScribeTests/Services/Recording/RecordingRepositoryTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/RecordingRepositoryTests`

  **What**: Test CRUD operations with in-memory ModelContainer. Verify save, fetchAll, update, delete all work correctly.

### Phase 3 — ML Services

- [ ] 16.1. Create VADConfig.swift and VADService.swift

  **Files**: Services/MLService/VAD/VADConfig.swift, Services/MLService/VAD/VADService.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create VADConfig (threshold, window size) and VADService implementing VADServiceProtocol. Uses FluidAudio's built-in VAD. hasSpeech(audioURL:) returns Bool. Loads model, runs inference, nullifies after use (sequential memory management). Reference: InferencePipeline.swift in embedded reference for model loading/nullification pattern.

  **Must NOT**: Do NOT implement custom VAD — use FluidAudio only. Do NOT coexist with other ML models in RAM.

- [ ] 16.2. Create VAD Tests

  **Files**: ScribeTests/Services/ML/VADServiceTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/VADServiceTests`

  **What**: Test VAD with mock audio (speech returns true, silence returns false). Verify model is nullified after use.

- [ ] 17.1. Create LanguageDetector.swift

  **Files**: Services/MLService/ASR/LanguageDetector.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create LanguageDetector implementing LanguageDetectionProtocol. Uses Whisper's built-in language detection output. Returns LanguageConfidence { language, confidence, isSwissGerman }. Threshold configurable in PipelineConfig.

  **Must NOT**: Do NOT implement custom language detection — use Whisper's capability.

- [ ] 17.2. Create LanguageDetector Tests

  **Files**: ScribeTests/Services/ML/LanguageDetectorTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/LanguageDetectorTests`

  **What**: Test with mock Whisper output: Swiss German returns isSwissGerman=true, English returns isSwissGerman=false.

- [ ] 18.1. Create WhisperCoreMLService.swift

  **Files**: Services/MLService/ASR/WhisperCoreMLService.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create WhisperCoreMLService implementing TranscriptionServiceProtocol. Loads Swiss German Whisper CoreML model from HuggingFace (jlnslv/whisper-large-v3-turbo-swiss-german-coreml, URL from PipelineConfig). Transcribes [Float32] to text. Sequential memory: load → run → nil.

  **Must NOT**: Do NOT load multiple models simultaneously. Do NOT implement custom ASR.

- [ ] 18.2. Create FallbackASRService.swift

  **Files**: Services/MLService/ASR/FallbackASRService.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create FallbackASRService implementing TranscriptionServiceProtocol. Uses FluidAudio Parakeet (reference: TranscriptionService in embedded InferencePipeline.swift) or general Whisper model for non-Swiss-German audio. Sequential memory management.

- [ ] 18.3. Create ASR Tests

  **Files**: ScribeTests/Services/ML/WhisperCoreMLServiceTests.swift, ScribeTests/Services/ML/FallbackASRServiceTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/WhisperCoreMLServiceTests`

  **What**: Test transcription with mock model output. Test FallbackASRService activation for non-Swiss-German.

- [ ] 19.1. Create DiarizationService.swift

  **Files**: Services/MLService/Diarization/DiarizationService.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create DiarizationService implementing DiarizationServiceProtocol. Reference: embedded InferencePipeline.swift DiarizationService uses OfflineDiarizerManager with clusteringThreshold 0.35, min 1 max 8 speakers. Falls back to single "Speaker 1" on failure. Model nullified after use.

  **Must NOT**: Do NOT implement custom diarization — use FluidAudio only.

- [ ] 19.2. Create Diarization Tests

  **Files**: ScribeTests/Services/ML/DiarizationServiceTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/DiarizationServiceTests`

  **What**: Test diarization with mock audio (produces multiple segments). Test fallback to "Speaker 1" on error.

- [ ] 20.1. Create LLMService.swift

  **Files**: Services/MLService/Summarization/LLMService.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create LLMService implementing SummarizationServiceProtocol. Reference: embedded LLMService.swift for EXACT prompt templates, Llama 3 chat template, map-refine logic, model download and caching logic. Model: Llama-3.2-3B-Instruct-Q4_K_M.gguf from PipelineConfig.llmModelDownloadURL. Single-pass (≤25,000 chars) or Map→Refine (>25,000 chars). Chunk size 12,000, overlap 1,200. Custom Llama 3 chat template MUST match the embedded reference EXACTLY. Model nullified after use.

  **Key Code** (reference: LLMService.swift — CRITICAL: preserve EXACT prompts and chat template):
  ```swift
  // Llama 3 Template (MUST match exactly)
  private static let llama3Template = Template(
      system: ("<|start_header_id|>system<|end_header_id|>\n\n", "<|eot_id|>"),
      user:   ("<|start_header_id|>user<|end_header_id|>\n\n",   "<|eot_id|>"),
      bot:    ("<|start_header_id|>assistant<|end_header_id|>\n\n", "<|eot_id|>"),
      stopSequence: "<|eot_id|>",
      systemPrompt: nil
  )
  ```

  **Must NOT**: Do NOT implement custom LLM inference. Do NOT load multiple models simultaneously.

- [ ] 20.2. Create ProgressTracker.swift

  **Files**: Services/MLService/Pipeline/ProgressTracker.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create ProgressTracker as @Observable class. Reference: InferencePipeline.swift has isProcessing, currentStep, progress fields. Tracks: current stage (VAD/LanguageDetection/ASR/Diarization/Summarization), stage count, percentage complete, stage descriptions.

- [ ] 20.3. Create InferencePipeline.swift

  **Files**: Services/MLService/Pipeline/InferencePipeline.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create InferencePipeline orchestrating 5 stages: VAD → Language Detection → ASR → Diarization → Summarization. Reference: embedded InferencePipeline.swift for the EXACT orchestration pattern, progress callbacks, and sequential model management (diarize → nil → transcribe → nil → summarize → nil). Supports cancellation via Task.checkCancellation(). Timeout per stage from PipelineConfig (60s).

  **Must NOT**: Do NOT implement ML logic directly — delegate to services. Do NOT load multiple models simultaneously.

- [ ] 20.4. Create ML Pipeline Tests

  **Files**: ScribeTests/Services/ML/LLMServiceTests.swift, ScribeTests/Services/ML/InferencePipelineTests.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/InferencePipelineTests`

  **What**: Test LLM summary generation with mock. Test pipeline: VAD returns false → early exit (ASR, Diarization NOT called). Test cancellation mid-pipeline. Test progress tracking.

### Phase 4 — VIPER Module Stacks

> Each module follows a consistent sub-task pattern:
> - X.1: Protocols + State
> - X.2: Interactor (business logic facade over Services)
> - X.3: Presenter + Router + Assembly (mediator, navigation, wiring)
> - X.4: Module Tests

- [ ] 21.1. RecordingListModule — Protocols + State

  **Files**: Modules/RecordingListModule/Interactor/RecordingListInteractorInput.swift, Modules/RecordingListModule/Interactor/RecordingListInteractorOutput.swift, Modules/RecordingListModule/Presenter/RecordingListViewOutput.swift, Modules/RecordingListModule/Presenter/RecordingListViewInput.swift, Modules/RecordingListModule/Presenter/RecordingListModuleInput.swift, Modules/RecordingListModule/Presenter/RecordingListModuleOutput.swift, Modules/RecordingListModule/Presenter/RecordingListState.swift, Modules/RecordingListModule/Router/RecordingListRouterInput.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all RecordingListModule protocols and state. InteractorInput: obtainRecordings(), deleteRecording(id:). InteractorOutput: didObtainRecordings([Recording]), didFailWithError(Error). ViewOutput: didTapRecord(), didTapRecording(id:), didTapSettings(), didDeleteRecording(id:). ViewInput: displayRecordings([Recording]), displayError(Error). ModuleInput: configureWith(delegate:). ModuleOutput: didSelectRecording(id:). State: recordings array, isRecording, micSource. RouterInput: openRecordingDetail(with:), openDeviceSettings(), openAgentGenerating().

  **Must NOT**: Do NOT implement business logic — define interfaces only.

- [ ] 21.2. RecordingListModule — Interactor

  **Files**: Modules/RecordingListModule/Interactor/RecordingListInteractor.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create RecordingListInteractor holding RecordingRepositoryProtocol and UnifiedRecorder (via protocol). Methods: obtainRecordings() → call repository.fetchAll() → output.didObtainRecordings(). deleteRecording(id:) → call repository.delete() → output.didObtainRecordings() (refresh). Weak output ref to Presenter.

  **Must NOT**: Do NOT access services directly from Presenter. Do NOT hold state (only dependencies + weak output).

- [ ] 21.3. RecordingListModule — Presenter, Router, Assembly

  **Files**: Modules/RecordingListModule/Presenter/RecordingListPresenter.swift, Modules/RecordingListModule/Router/RecordingListRouter.swift, Modules/RecordingListModule/Assembly/RecordingListAssembly.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Presenter is @Observable, holds RecordingListState. Mediates between View and Interactor. Assembly wires all components.

  **Must NOT**: Do NOT put business logic in Presenter — Presenter only mediates.

- [ ] 21.4. RecordingListModule — Tests

  **Files**: ScribeTests/Modules/RecordingList/RecordingListInteractorTests.swift, ScribeTests/Modules/RecordingList/RecordingListPresenterTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/RecordingListInteractorTests`

  **What**: Test Interactor with MockRecordingRepository: obtainRecordings → fetchAll called → output gets results. Test Presenter with MockInteractor: didTriggerViewReady → interactor.obtainRecordings called.

- [ ] 22.1. RecordingDetailModule — Protocols + State

  **Files**: Modules/RecordingDetailModule/Interactor/RecordingDetailInteractorInput.swift, Modules/RecordingDetailModule/Interactor/RecordingDetailInteractorOutput.swift, Modules/RecordingDetailModule/Presenter/RecordingDetailViewOutput.swift, Modules/RecordingDetailModule/Presenter/RecordingDetailViewInput.swift, Modules/RecordingDetailModule/Presenter/RecordingDetailModuleInput.swift, Modules/RecordingDetailModule/Presenter/RecordingDetailModuleOutput.swift, Modules/RecordingDetailModule/Presenter/RecordingDetailState.swift, Modules/RecordingDetailModule/Router/RecordingDetailRouterInput.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all RecordingDetailModule protocols and state. ModuleInput accepts recording ID. State: recording, selectedTab (summary/transcript/mindmap), isProcessing. Router: embedWaveformPlayback(), embedTranscript(), embedSummary(), embedMindMap().

- [ ] 22.2. RecordingDetailModule — Interactor

  **Files**: Modules/RecordingDetailModule/Interactor/RecordingDetailInteractor.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create RecordingDetailInteractor holding RecordingRepositoryProtocol. Receives recording ID via ModuleInput, loads full recording. Methods: obtainRecording(id:), updateRecording(_:).

- [ ] 22.3. RecordingDetailModule — Presenter, Router, Assembly

  **Files**: Modules/RecordingDetailModule/Presenter/RecordingDetailPresenter.swift, Modules/RecordingDetailModule/Router/RecordingDetailRouter.swift, Modules/RecordingDetailModule/Assembly/RecordingDetailAssembly.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Presenter @Observable holds RecordingDetailState. Coordinates sub-module communication. Assembly wires all components and embeds sub-modules.

- [ ] 22.4. RecordingDetailModule — Tests

  **Files**: ScribeTests/Modules/RecordingDetail/RecordingDetailInteractorTests.swift, ScribeTests/Modules/RecordingDetail/RecordingDetailPresenterTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/RecordingDetailInteractorTests`

  **What**: Test Interactor loads recording by ID. Test Presenter mediation.

- [ ] 23.1. WaveformPlaybackModule — Protocols + State

  **Files**: Modules/WaveformPlaybackModule/Interactor/WaveformPlaybackInteractorInput.swift, Modules/WaveformPlaybackModule/Interactor/WaveformPlaybackInteractorOutput.swift, Modules/WaveformPlaybackModule/Presenter/WaveformPlaybackViewOutput.swift, Modules/WaveformPlaybackModule/Presenter/WaveformPlaybackViewInput.swift, Modules/WaveformPlaybackModule/Presenter/WaveformPlaybackModuleInput.swift, Modules/WaveformPlaybackModule/Presenter/WaveformPlaybackState.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all WaveformPlaybackModule protocols and state. No Router (embedded sub-module). State: isPlaying, currentTime, duration, speed, waveformBars.

- [ ] 23.2. WaveformPlaybackModule — Interactor

  **Files**: Modules/WaveformPlaybackModule/Interactor/WaveformPlaybackInteractor.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create WaveformPlaybackInteractor holding AudioPlayerProtocol and WaveformAnalyzer. Methods: obtainWaveformData(), playAudio(), pauseAudio(), seekTo(_:), cycleSpeed(). Delegates to services via protocols.

- [ ] 23.3. WaveformPlaybackModule — Presenter + Assembly

  **Files**: Modules/WaveformPlaybackModule/Presenter/WaveformPlaybackPresenter.swift, Modules/WaveformPlaybackModule/Assembly/WaveformPlaybackAssembly.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Presenter @Observable holds PlaybackState. ModuleInput accepts audio file URL. Assembly wires components. No Router.

- [ ] 23.4. WaveformPlaybackModule — Tests

  **Files**: ScribeTests/Modules/WaveformPlayback/WaveformPlaybackInteractorTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/WaveformPlaybackInteractorTests`

  **What**: Test Interactor with MockAudioPlayer: playAudio → player.play() called, cycleSpeed → speed incremented.

- [ ] 24.1. TranscriptModule — Protocols + State

  **Files**: Modules/TranscriptModule/Interactor/TranscriptInteractorInput.swift, Modules/TranscriptModule/Interactor/TranscriptInteractorOutput.swift, Modules/TranscriptModule/Presenter/TranscriptViewOutput.swift, Modules/TranscriptModule/Presenter/TranscriptViewInput.swift, Modules/TranscriptModule/Presenter/TranscriptModuleInput.swift, Modules/TranscriptModule/Presenter/TranscriptState.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create TranscriptModule protocols and state. InteractorInput: obtainTranscriptSegments(), renameSpeaker(from:to:). ViewOutput: didTapSpeaker(speakerId:). State: parsed segments, selectedSpeakerForRename. No Router (embedded). Reference: RecordingDetailView.swift TranscriptInteractiveView for the `[Speaker N - MM:SS]` parsing pattern.

- [ ] 24.2. TranscriptModule — Interactor

  **Files**: Modules/TranscriptModule/Interactor/TranscriptInteractor.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create TranscriptInteractor holding RecordingRepositoryProtocol. Reference: RecordingDetailView.swift parseTranscript function parses `[Speaker N - MM:SS]` format into TranscriptSegment structs. **IMPORTANT**: renameSpeaker must update rawTranscript, actionItems, AND meetingNotes JSON (all three fields) — see RecordingDetailView.swift lines 254-264.

- [ ] 24.3. TranscriptModule — Presenter + Assembly

  **Files**: Modules/TranscriptModule/Presenter/TranscriptPresenter.swift, Modules/TranscriptModule/Assembly/TranscriptAssembly.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Presenter @Observable holds TranscriptState. Handles rename flow: View taps speaker → Presenter asks Interactor to rename. Assembly wires components.

- [ ] 24.4. TranscriptModule — Tests

  **Files**: ScribeTests/Modules/Transcript/TranscriptInteractorTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/TranscriptInteractorTests`

  **What**: Test renameSpeaker updates all 3 fields (rawTranscript, actionItems, meetingNotes). Test segment parsing.

- [ ] 25.1. SummaryModule — Protocols + State + Interactor

  **Files**: Modules/SummaryModule/Interactor/SummaryInteractorInput.swift, Modules/SummaryModule/Interactor/SummaryInteractorOutput.swift, Modules/SummaryModule/Presenter/SummaryViewOutput.swift, Modules/SummaryModule/Presenter/SummaryViewInput.swift, Modules/SummaryModule/Presenter/SummaryModuleInput.swift, Modules/SummaryModule/Presenter/SummaryState.swift, Modules/SummaryModule/Interactor/SummaryInteractor.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all SummaryModule protocols, state, and Interactor. Simple read-only module. Interactor obtains and parses summary from Recording (TopicSections). State: topic sections, action items, loading.

- [ ] 25.2. SummaryModule — Presenter + Assembly + Tests

  **Files**: Modules/SummaryModule/Presenter/SummaryPresenter.swift, Modules/SummaryModule/Assembly/SummaryAssembly.swift, ScribeTests/Modules/Summary/SummaryInteractorTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/SummaryInteractorTests`

  **What**: Presenter @Observable holds SummaryState. Assembly wires components. Test Interactor returns parsed summary from mock recording.

- [ ] 26.1. MindMapModule — Protocols + State + Interactor

  **Files**: Modules/MindMapModule/Interactor/MindMapInteractorInput.swift, Modules/MindMapModule/Interactor/MindMapInteractorOutput.swift, Modules/MindMapModule/Presenter/MindMapViewOutput.swift, Modules/MindMapModule/Presenter/MindMapViewInput.swift, Modules/MindMapModule/Presenter/MindMapModuleInput.swift, Modules/MindMapModule/Presenter/MindMapState.swift, Modules/MindMapModule/Interactor/MindMapInteractor.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all MindMapModule protocols, state, and Interactor. Simple read-only module. Interactor parses MindMapNode JSON tree. State: mind map nodes, loading.

- [ ] 26.2. MindMapModule — Presenter + Assembly + Tests

  **Files**: Modules/MindMapModule/Presenter/MindMapPresenter.swift, Modules/MindMapModule/Assembly/MindMapAssembly.swift, ScribeTests/Modules/MindMap/MindMapInteractorTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/MindMapInteractorTests`

  **What**: Presenter @Observable holds MindMapState. Assembly wires. Test Interactor parses MindMapNode JSON into recursive tree.

- [ ] 27.1. AgentGeneratingModule — Protocols + State + Interactor

  **Files**: Modules/AgentGeneratingModule/Interactor/AgentGeneratingInteractorInput.swift, Modules/AgentGeneratingModule/Interactor/AgentGeneratingInteractorOutput.swift, Modules/AgentGeneratingModule/Presenter/AgentGeneratingViewOutput.swift, Modules/AgentGeneratingModule/Presenter/AgentGeneratingViewInput.swift, Modules/AgentGeneratingModule/Presenter/AgentGeneratingModuleInput.swift, Modules/AgentGeneratingModule/Presenter/AgentGeneratingModuleOutput.swift, Modules/AgentGeneratingModule/Presenter/AgentGeneratingState.swift, Modules/AgentGeneratingModule/Interactor/AgentGeneratingInteractor.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all AgentGeneratingModule protocols, state, and Interactor. Interactor delegates to InferencePipeline: startProcessing(recordingId:), cancelProcessing(). State: processing stage, progress percentage, isProcessing. Has ModuleOutput for completion/failure reporting. Reference: InferencePipeline.swift for progress format strings.

- [ ] 27.2. AgentGeneratingModule — Presenter + Assembly + Tests

  **Files**: Modules/AgentGeneratingModule/Presenter/AgentGeneratingPresenter.swift, Modules/AgentGeneratingModule/Assembly/AgentGeneratingAssembly.swift, ScribeTests/Modules/AgentGenerating/AgentGeneratingInteractorTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/AgentGeneratingInteractorTests`

  **What**: Presenter @Observable holds AgentGeneratingState. Tracks progress from Interactor. Assembly wires. Test: startProcessing → pipeline.process() called, cancelProcessing → pipeline.cancel() called.

- [ ] 28.1. DeviceSettingsModule — Protocols + State

  **Files**: Modules/DeviceSettingsModule/Interactor/DeviceSettingsInteractorInput.swift, Modules/DeviceSettingsModule/Interactor/DeviceSettingsInteractorOutput.swift, Modules/DeviceSettingsModule/Presenter/DeviceSettingsViewOutput.swift, Modules/DeviceSettingsModule/Presenter/DeviceSettingsViewInput.swift, Modules/DeviceSettingsModule/Presenter/DeviceSettingsModuleInput.swift, Modules/DeviceSettingsModule/Presenter/DeviceSettingsState.swift, Modules/DeviceSettingsModule/Router/DeviceSettingsRouterInput.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create all DeviceSettingsModule protocols and state. InteractorInput: startScan(), connectToDevice(_:), disconnect(). ViewOutput: didTapScan(), didTapDevice(_:), didTapDisconnect(). State: discovered devices, connection state, isScanning. RouterInput: closeCurrentModule().

- [ ] 28.2. DeviceSettingsModule — Interactor

  **Files**: Modules/DeviceSettingsModule/Interactor/DeviceSettingsInteractor.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create DeviceSettingsInteractor holding BluetoothDeviceScannerProtocol and DeviceConnectionManager. Methods startScan(), connectToDevice(_:), disconnect(). Delegates to BLE services via protocols. Reference: embedded DeviceSettingsView.swift for UI state management.

  **Must NOT**: Do NOT put BLE logic in Presenter.

- [ ] 28.3. DeviceSettingsModule — Presenter, Router, Assembly

  **Files**: Modules/DeviceSettingsModule/Presenter/DeviceSettingsPresenter.swift, Modules/DeviceSettingsModule/Router/DeviceSettingsRouter.swift, Modules/DeviceSettingsModule/Assembly/DeviceSettingsAssembly.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Presenter @Observable holds DeviceSettingsState. Receives View events, forwards to Interactor. Router handles module dismissal. Assembly wires all components.

- [ ] 28.4. DeviceSettingsModule — Tests

  **Files**: ScribeTests/Modules/DeviceSettings/DeviceSettingsInteractorTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/DeviceSettingsInteractorTests`

  **What**: Test Interactor scan: startScan() → scanner.startScan() called → output.didDiscoverDevices() with results.

### Phase 5 — Views

> All views follow strict VIPER: View reads state from Presenter, forwards user actions to Presenter. Zero business logic in View.
> Reference: See embedded "UI Layout Reference" section for exact dimensions, colors, and animations.

- [ ] 29.1. RecordingListModule — RecordingListView

  **Files**: Modules/RecordingListModule/View/RecordingListView.swift
  **Category**: visual-engineering
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Create RecordingListView. Reference: embedded RecordingListView.swift for EXACT layout. NavigationStack, PlainListStyle. DashboardHeaderView (placeholder). RecordingCardView per recording sorted by createdAt. Empty state with mic.slash icon. Toolbar: mic.badge.plus button (scribeRed). Bottom: mic indicator badge (internal/external), RecordButtonView. Background: dark = Color.black, light = gray.opacity(0.1). STRICT VIPER: View reads ALL state from Presenter (output). Zero business logic. All user actions forwarded: didTapRecord, didTapRecording, didTapSettings.

  **Must NOT**: Do NOT change any visual appearance — exact match required. Do NOT put business logic in View.

- [ ] 29.2. RecordingListModule — RecordingCardView + RecordButtonView

  **Files**: Modules/RecordingListModule/View/RecordingCardView.swift, Modules/RecordingListModule/View/RecordButtonView.swift
  **Category**: visual-engineering
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: RecordingCardView: scribeCardStyle, title (headline bold, lineLimit 2), duration badge, category tag (scribeRed tinted), date/time. Pure rendering. Reference: embedded RecordingCardView.swift. RecordButtonView: Reference: embedded RecordButtonView.swift — 80x80 outer, 70x70 inner. Outer ring: scribeRed.opacity(0.3), scaleEffect 1.5x when recording. Inner: scribeRed (0.8 opacity), shadow 10. Recording: 24x24 white stop; Idle: mic.fill (28pt bold white). Animation: easeInOut 1.5s repeatForever. Disabled: opacity 0.5. Calls output.didTapRecord() on tap.

  **Must NOT**: Do NOT change animation timing or visual design.

- [ ] 29.3. RecordingListModule — View Tests

  **Files**: ScribeTests/Modules/RecordingList/RecordingListViewTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/RecordingListViewTests`

  **What**: Test RecordingListView renders Presenter state (3 mock recordings → 3 cards). Test RecordButtonView tap forwards output.didTapRecord().

- [ ] 30.1. RecordingDetailModule View + WaveformPlaybackView

  **Files**: Modules/RecordingDetailModule/View/RecordingDetailView.swift, Modules/WaveformPlaybackModule/View/WaveformPlaybackView.swift
  **Category**: visual-engineering
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: RecordingDetailView: Reference: embedded RecordingDetailView.swift. ZStack bottom floating CTA, error banner, segmented picker (Summary|Transcript|Mind Map), ScrollView, embedded WaveformPlaybackView. WaveformPlaybackView: 50 bars, spacing 3pt, corner radius 2pt, min height 4pt. Reference: embedded WaveformView in RecordingDetailView.swift lines 292-330. Played: scribeRed, unplayed: secondary.opacity(0.3). Controls: skip back 15s, play/pause 44pt scribeRed, skip forward 15s, speed capsule. STRICT VIPER.

  **Must NOT**: Do NOT change visual appearance. Do NOT put playback logic in View.

- [ ] 30.2. RecordingDetail + Waveform View Tests

  **Files**: ScribeTests/Modules/RecordingDetail/RecordingDetailViewTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/RecordingDetailViewTests`

  **What**: Test RecordingDetailView renders recording from Presenter state. Test WaveformPlaybackView reads playback state from Presenter.

- [ ] 31.1. TranscriptModule View + SummaryModule View

  **Files**: Modules/TranscriptModule/View/TranscriptTabView.swift, Modules/SummaryModule/View/SummaryTabView.swift
  **Category**: visual-engineering
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: TranscriptTabView: Reference: embedded TranscriptInteractiveView in RecordingDetailView.swift lines 402-487. Displays speaker segments with [Speaker N - MM:SS] parsing. Tap speaker label → Presenter handles rename (didTapSpeaker). Rename alert triggered by Presenter state. SummaryTabView: Reference: RecordingDetailView.swift lines 119-183. Renders TopicSections as headed lists with speaker-attributed action items. Empty state: doc.text.magnifyingglass icon. STRICT VIPER.

  **Must NOT**: Do NOT put parsing or rename logic in View. Do NOT change transcript format.

- [ ] 31.2. Transcript + Summary View Tests

  **Files**: ScribeTests/Modules/Transcript/TranscriptTabViewTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/TranscriptTabViewTests`

  **What**: Test TranscriptTabView forwards speaker tap to Presenter. Test SummaryTabView renders TopicSections from Presenter.

- [ ] 32.1. MindMapModule View

  **Files**: Modules/MindMapModule/View/MindMapView.swift
  **Category**: visual-engineering
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Reference: embedded MindMapView in RecordingDetailView.swift lines 358-399. Recursive tree rendering of MindMapNode. Branch connectors. Depth-based styling (2+ levels). Empty state: network icon. STRICT VIPER: reads nodes from Presenter only.

  **Must NOT**: Do NOT change mind map rendering logic.

- [ ] 33.1. AgentGeneratingModule View

  **Files**: Modules/AgentGeneratingModule/View/AgentGeneratingView.swift
  **Category**: visual-engineering
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Reference: embedded AgentGeneratingView.swift for EXACT animation parameters. iOS 18+: MeshGradient 3x3 (see reference for exact points and colors). Fallback: LinearGradient (black, scribeRed.opacity(0.8), indigo). Pulsating circles: 140pt/100pt/80pt with waveform.circle.fill. "ARTIFICIAL INTELLIGENCE" (headline, white 0.7). Progress text (title3, white) with .contentTransition(.numericText()). Progress bar: 250x6pt capsule white fill. Animations: mesh 4.0s easeInOut repeatForever, circle pulse 1.5s. STRICT VIPER: reads progress from Presenter.

  **Must NOT**: Do NOT change animation timing or gradient colors.

- [ ] 34.1. DeviceSettingsModule View

  **Files**: Modules/DeviceSettingsModule/View/DeviceSettingsView.swift
  **Category**: visual-engineering
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Reference: embedded DeviceSettingsView.swift for EXACT layout. ConnectionStatusCard (scribeCardStyle): status dot, device name, Disconnect button. DeviceListCard (scribeCardStyle): scan button, device list with RSSI/battery. DeviceRow: mic icon, name, RSSI badge, battery, chevron. Status colors: connected/green, connecting/yellow, failed/scribeRed, disconnected/secondary. ScanButton: triggers 10-second scan. CRITICAL: Use @Observable correctly (no @State wrapping @Observable — reference: DeviceSettingsView.swift comment at line 9).

  **Must NOT**: Do NOT change visual appearance. Do NOT wrap @Observable classes in @State.

- [ ] 34.2. DeviceSettings View Test

  **Files**: ScribeTests/Modules/DeviceSettings/DeviceSettingsViewTests.swift
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/DeviceSettingsViewTests`

  **What**: Test DeviceSettingsView renders connection state from Presenter. Test connected device shows green status.

### Phase 6 — App Wiring + Integration + Documentation

- [ ] 35.1. Wire ScribeApp.swift + AppAssembly with Real Services

  **Files**: App/ScribeApp.swift, App/AppAssembly.swift, App/ServiceRegistry.swift
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Update ScribeApp.swift with @main entry point, SwiftData ModelContainer (reference: embedded ScribeApp.swift for exact structure), .preferredColorScheme(.dark), WindowGroup with RecordingListModule View as root. Update AppAssembly to wire real services (replace all stubs). Register all 8 module Assemblies. Set up NavigationStack.

  **Must NOT**: Do NOT implement business logic in App layer. Do NOT use global singletons — all DI through Assembly chain.

- [ ] 35.2. Wire Navigation and Module Communication

  **Files**: App/AppAssembly.swift (update), Modules/RecordingListModule/Router/RecordingListRouter.swift (update)
  **Category**: unspecified-low
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Wire navigation: RecordingListModule Router → RecordingDetailModule (push), DeviceSettingsModule (sheet), AgentGeneratingModule (sheet). Wire all ModuleInput/ModuleOutput for inter-module data passing. Wire sub-module embedding in RecordingDetailModule.

- [ ] 35.3. Full App Build Verification

  **Files**: None (verification only)
  **Category**: quick
  **Verify**: `xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build && xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' test`

  **What**: Run full build and test suite. Verify all Phase 1-5 code compiles, all tests pass, zero print statements, zero force unwraps, zero empty catch blocks. Save evidence to .sisyphus/evidence/task-35-app-build.txt.

- [ ] 36.1. Integration Tests — Recording Lifecycle

  **Files**: ScribeTests/Integration/RecordingLifecycleTests.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/RecordingLifecycleTests`

  **What**: Create integration tests for full recording lifecycle: start recording (internal or BLE) → stop → save to SwiftData → ML pipeline → transcript/summary/mindmap. All with mock services.

  **Must NOT**: Do NOT require real hardware for integration tests.

- [ ] 36.2. Integration Tests — Error Handling + Module Communication

  **Files**: ScribeTests/Integration/ErrorHandlingTests.swift, ScribeTests/Integration/ModuleCommunicationTests.swift
  **Category**: unspecified-high
  **Verify**: `xcodebuild -scheme Scribe test -only-testing:ScribeTests/IntegrationTests`

  **What**: Test error scenarios: BLE disconnect mid-recording, ML pipeline failure, empty recording (VAD no speech), app backgrounded during pipeline, corrupted audio. Test cross-module ModuleInput/ModuleOutput communication.

- [ ] 37.1. Documentation — README + Code Documentation

  **Files**: README.md, various public API files (documentation comments)
  **Category**: writing
  **Verify**: `xcodebuild -scheme Scribe build`

  **What**: Update README.md with current VIPER architecture: module structure (8 modules with Assembly/Interactor/Presenter/Router/View), services layer, core layer, updated ML pipeline (VAD → Language Detection → Whisper ASR → Diarization → LLM), unified Opus format, config-driven model swapping, SPM dependencies, build/test commands. Add documentation comments to all public APIs. Remove outdated references (PLAN.md, Phase 4 Apple Notes export).

  **Must NOT**: Do NOT add new features to README. Do NOT document internal implementation — only public API contracts.

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run SEQUENTIALLY. Present consolidated results to user for review and approval.
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**
> **Never mark F1-F4 as checked before getting user's okay.**

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, grep, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | VIPER Violations [N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `xcodebuild -scheme Scribe build` + `xcodebuild test`. Review all changed files for: `as!`/`try!`, empty catches, print statements in prod, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names. Verify no file exceeds 400 lines. Verify VIPER module structure.
  Output: `Build [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute QA scenarios. Test edge cases: empty state, invalid input, rapid actions. Human verification points: BLE real hardware, UI visual match, end-to-end recording flow. Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Human Checks [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What", read actual diff. Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT" compliance. Verify VIPER architecture compliance: module boundaries respected, no cross-module direct dependencies.
  Output: `Tasks [N/N compliant] | VIPER Violations [N] | VERDICT`

---

## Commit Strategy

- **Phase 1**: `chore(scaffold): create VIPER project structure with core, services, and modules`
- **Phase 2**: `feat(services): implement BLE, audio, and recording services`
- **Phase 3**: `feat(ml): implement ML pipeline services with VAD and Swiss German ASR`
- **Phase 4**: `feat(modules): implement all 8 VIPER module stacks`
- **Phase 5**: `feat(ui): implement all module views with pixel-perfect design`
- **Phase 6**: `feat(app): wire app, integration tests, documentation`

---

## Success Criteria

### Verification Commands
```bash
xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build  # Expected: BUILD SUCCEEDED
xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' test   # Expected: All tests pass
```

### Final Checklist
- [ ] All "Must Have" features present
- [ ] All "Must NOT Have" patterns absent
- [ ] All tests pass