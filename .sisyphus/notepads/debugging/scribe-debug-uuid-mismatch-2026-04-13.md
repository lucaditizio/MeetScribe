# Debug History: UUID Mismatch in AgentGenerating Pipeline

## Issue Summary
When user presses "Generate Transcript" on a recording:
- **Waveform shows**: `414BEC76-899A-416D-B2B8-75607ECDD62C`
- **Pipeline receives**: `7C09565D-FD73-4BC4-8825-187957523832` (different, fictional UUID)

The audio file loads correctly (414BEC76...), but the ML pipeline is invoked with a different UUID.

---

## Debug Logs

### Latest Log (2026-04-13)
```
didObtainRecordings called: 11 recordings
Bluetooth powered on
Loading audio from URL
Audio loaded successfully
Starting waveform analysis for: 414BEC76-899A-416D-B2B8-75607ECDD62C_16kHz.caf
<<<< FigApplicationStateMonitor >>>> signalled err=-19431 at <>:474
<<<< FigApplicationStateMonitor >>>> signalled err=-19431 at <>:474
Read 127637 samples, duration: 7.9773125s
Waveform analysis complete: 51 bars
LLMService initialized
ProgressTracker initialized with 5 stages
InferencePipeline initialized
DEBUG SHEET: presenter.state.recording?.id = 7C09565D-FD73-4BC4-8825-187957523832
DEBUG startProcessing: recordingId=7C09565D-FD73-4BC4-8825-187957523832
DEBUG fetch result: 7C09565D-FD73-4BC4-8825-187957523832 for requested 7C09565D-FD73-4BC4-8825-187957523832
Starting pipeline processing for recording: 7C09565D-FD73-4BC4-8825-187957523832
Loaded 514644 bytes from audio file
Stage 1/5: VAD started
Stage VAD: 0.000000% complete
VAD manager not initialized
Stage VAD: 100.000000% complete
Stage 1/5: VAD completed, speech detected: false
```

### Earlier Log (Before Fixes)
```
LLMService initialized
ProgressTracker initialized with 5 stages
InferencePipeline initialized 
Audio file not found: /var/mobile/Containers/Data/Application/6B9F6E6D-2CA6-4609-9262-BF0FD0500295/Documents/10C9F4D4-A45A-4E15-8D4B-AB2EA8FB9B06_16kHz.caf
```

---

## Key Observations

1. **Waveform loads correct audio file**: `414BEC76-899A-416D-B2B8-75607ECDD62C_16kHz.caf` - audio file exists and loads
2. **Pipeline ID is wrong**: `7C09565D-FD73-4BC4-8825-187957523832` - completely different UUID
3. **Repository returns consistent wrong ID**: Debug shows `fetch result: 7C09565D... for requested 7C09565D...` - repository IS returning the wrong recording

---

## Code Flow Analysis

### Flow 1: RecordingList → RecordingDetail (Correct)

```
RecordingListView (user taps recording)
  → router.selectedRecording = recording  [RecordingListRouter line 34]
  → SwiftUI .navigationDestination(item:) triggers
  → router.recordingDetailView(for: recording)  [RecordingListRouter line 44-46]
  → appAssembly.makeRecordingDetailModule(recordingId: recording.id)  [AppAssembly line 30-32]
  → RecordingDetailAssembly.createModule(recordingId: "414BEC76...")  [line 8-12]
```

### Flow 2: Inside RecordingDetailAssembly

```swift
// Line 13: Creates router
let router = RecordingDetailRouter(...)

// Line 15-18: Creates interactor
let interactor = RecordingDetailInteractor(
    output: nil,
    recordingRepository: recordingRepository
)

// Line 20-25: Creates WaveformPresenter with SAME recordingId
let waveformPresenter = WaveformPlaybackAssembly.createModule(
    recordingId: recordingId,  // ← SAME ID passed
    recordingRepository: recordingRepository,
    audioPlayer: audioPlayer,
    waveformAnalyzer: WaveformAnalyzer()
)

// Line 27-32: Creates presenter
let presenter = RecordingDetailPresenter(
    view: nil,
    interactor: interactor,
    router: router,
    waveformPresenter: waveformPresenter
)

// Line 34: Wires output
interactor.output = presenter

// Line 36: Fetches recording with SAME recordingId
interactor.obtainRecording(id: recordingId)  // ← SAME ID
```

### Flow 3: Sheet Presentation (Generate Transcript)

```swift
// RecordingDetailView.swift line 51-56
.sheet(isPresented: $router.isShowingAgentGenerating) {
    AppAssembly.shared.makeAgentGeneratingModule(
        recordingId: presenter.state.recording?.id ?? UUID(),  // ← Uses state.recording
        output: nil
    )
}
```

---

## What Was Tried

### Fix 1: pendingRecordingId (Failed)
Added `pendingRecordingId` to Router to capture recording.id at button press time.

**Result**: Still wrong UUID - the issue wasn't in sheet timing.

### Fix 2: Direct state access (Failed)
Changed sheet to use `presenter.state.recording?.id` directly instead of `router.pendingRecordingId`.

**Result**: Still wrong UUID - `state.recording` itself has wrong ID.

### Fix 3: InferencePipeline filePath (Fixed)
Changed from using `recording.filePath` (absolute with container UUID) to `fileName` + Documents directory.

```swift
// Before (broken):
let fileURL = URL(fileURLWithPath: recording.filePath)

// After (fixed):
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let fileURL = documentsPath.appendingPathComponent(recording.fileName)
```

**Result**: Audio file now loads correctly.

### Fix 4: VAD Manager Initialization (Pending)
VAD fails with "VAD manager not initialized" because `process(buffer:)` doesn't call `loadManager()` first.

---

## Hypotheses

### Hypothesis 1: SwiftData Predicate Capture Bug
**Evidence from bg_f676fecb**:

In `RecordingRepository.fetch(by:)`:
```swift
// POTENTIAL BUG - captures external var directly
let descriptor = FetchDescriptor<Recording>(predicate: #Predicate { $0.id == id })
```

In `RecordingRepository.delete()`:
```swift
// CORRECT pattern - captures to local first
let recordingId = recording.id
let descriptor = FetchDescriptor<Recording>(predicate: #Predicate { recording in
    recording.id == recordingId
})
```

**Why this might matter**: SwiftData's #Predicate macro may have issues capturing external variables correctly.

### Hypothesis 2: Waveform vs Detail Different Fetch Timing
- WaveformPresenter calls `obtainWaveformData()` on `didTriggerViewReady()`
- RecordingDetailPresenter calls `obtainRecording()` in Assembly after creation
- These are concurrent async operations

If Waveform's fetch completes FIRST with correct ID (414BEC76...), but Detail's fetch somehow gets corrupted...

### Hypothesis 3: Shared ModelContainer Issue
Both WaveformInteractor and RecordingDetailInteractor use `services.recordingRepository` which is a singleton with a shared `SwiftDataModelContainer`.

If SwiftData's context has stale row state, consecutive fetches might return wrong objects.

---

## Files Involved

| File | Relevance |
|------|-----------|
| `Scribe/Modules/RecordingDetailModule/Assembly/RecordingDetailAssembly.swift` | Creates both WaveformPresenter and RecordingDetailPresenter with same recordingId |
| `Scribe/Modules/RecordingDetailModule/Interactor/RecordingDetailInteractor.swift` | Calls `repository.fetch(by: id)` - returns wrong recording |
| `Scribe/Modules/RecordingDetailModule/Presenter/RecordingDetailPresenter.swift` | `didObtainRecording()` sets `state.recording` |
| `Scribe/Modules/WaveformPlaybackModule/Interactor/WaveformPlaybackInteractor.swift` | Correctly fetches and loads audio |
| `Scribe/Services/RecordingService/RecordingRepository.swift` | `fetch(by:)` has potential predicate bug |
| `Scribe/Modules/AgentGeneratingModule/Interactor/AgentGeneratingInteractor.swift` | Receives wrong recordingId |
| `Scribe/App/AppAssembly.swift` | Creates modules with recordingId.uuidString |

---

## Debug Additions (Current)

### 1. RecordingDetailAssembly (just added)
```swift
public static func createModule(...) {
    print("DEBUG Assembly: createModule called with recordingId=\(recordingId)")
    ...
}
```

### 2. AgentGeneratingInteractor (already present)
```swift
ScribeLogger.info("DEBUG startProcessing: recordingId=\(rid)", category: .ml)
ScribeLogger.info("DEBUG fetch result: \(recording?.id.uuidString ?? "NIL") for requested \(rid)", category: .ml)
```

---

## Next Debug Steps

1. **Run with new Assembly debug log** to confirm what ID is received at Assembly level
2. If Assembly receives correct ID (414BEC76...) → bug is in RecordingDetailInteractor or Repository
3. If Assembly receives wrong ID (7C09565D...) → bug is in AppAssembly or RecordingListRouter

---

## Related Issues Found

### VAD Manager Not Initialized
`VADService.process(buffer:)` doesn't initialize `vadManager` before calling `detectSpeech()`.

```swift
// VADService.swift line 13
public func process(buffer: Data) -> Bool {
    return detectSpeech(in: samples)  // Line 41 checks vadManager which is nil!
}

// But hasSpeech(audioURL:) (line 22) DOES call loadManager() first
public func hasSpeech(audioURL: URL) async throws -> Bool {
    try await loadManager()  // ← This initializes vadManager
    ...
}
```

**Fix needed**: Either call `loadManager()` before `process()`, or change Pipeline to use `hasSpeech()` instead.
