# Audio Sample Rate Converter - Implementation Plan

## TL;DR

> Fix internal microphone crash by recording at hardware native rate (48kHz) and converting to 16kHz asynchronously before ML pipeline.
> 
> Deliverables: AudioSampleRateConverter service, InternalMicRecorder fix, wiring for BLE + internal mic
> Estimated Effort: Medium
> Parallel Execution: NO - sequential (recorder → converter → pipeline)

---

## Context

### Problem
Internal microphone crashes on recording start:
```
Format mismatch: input hw <...48000Hz...>, client format <...16000Hz...>
Failed to create tap due to format mismatch
```

### Root Cause
`InternalMicRecorder` tries to install tap at 16kHz, but internal iOS mic runs at 48kHz hardware native.

### Key Insight
**Conversion does NOT need to be real-time.** ML pipeline processes asynchronously - can lag a few seconds.

### Microphone Sources
- **Internal iOS Mic**: 48kHz native → needs conversion
- **Bluetooth Mic**: typically 16kHz → may not need conversion

---

## Work Objectives

### Core Objective
Fix crash while supporting both microphone sources with robust 48kHz→16kHz conversion.

### Concrete Deliverables
- [ ] AudioSampleRateConverter service (NOT VIPER - see analysis)
- [ ] InternalMicRecorder records at hardware rate (no forced format)
- [ ] Conversion runs async before ML pipeline
- [ ] BLE mic still works (may already be 16kHz)

### Must Have
- [ ] Internal mic records without crash
- [ ] BLE mic continues to work
- [ ] Async conversion produces correct 16kHz output
- [ ] ML pipeline receives valid audio

### Must NOT
- [ ] Block UI during conversion (must be async)
- [ ] Require real-time streaming conversion
- [ ] Hardcode 48kHz (must detect dynamically)

---

## GAP ANALYSIS (Robustness, VIPER Compatibility, Efficiency, Cleanliness)

### 1. ROBUSTNESS ISSUES

**Gap 1.1: No sample rate detection**
- Current plan assumes conversion is always needed
- Missing: dynamic check if source is already 16kHz
- Risk: Unnecessary conversion, wasted compute
- Fix: Detect source sample rate before converting

**Gap 1.2: No error handling for conversion failure**
- AVAudioConverter can fail (invalid format, corrupt file)
- Missing: error cases, fallback strategy
- Risk: ML pipeline receives bad audio silently
- Fix: Add error enum, retry logic, validation

**Gap 1.3: No memory management for large files**
- Converting long recordings needs buffer allocation
- Missing: streaming conversion for large files
- Risk: Memory pressure crash on long recordings
- Fix: Process in chunks, not all in memory

**Gap 1.4: BLE mic edge cases**
- BLE can be 44.1kHz, not just 16kHz
- Missing: dynamic sample rate handling
- Risk: Conversion fails for some BLE devices
- Fix: Detect and convert any rate → 16kHz

### 2. VIPER COMPATIBILITY ISSUES

**Gap 2.1: VIPER unnecessary for this service**
- Current plan creates full VIPER module
- Existing codebase: Services are plain classes (OpusEncoder, AudioConverter)
- VIPER adds boilerplate without benefit
- Fix: Use plain class pattern (matches OpusEncoder)

**Gap 2.2: No protocol definition**
- Missing: AudioSampleRateConverterProtocol
- Can't mock for testing
- Risk: Hard to unit test
- Fix: Add protocol if testing needed

### 3. COMPUTE EFFICIENCY ISSUES

**Gap 3.1: Unnecessary conversion**
- If BLE already at 16kHz, skip conversion
- Missing: check before convert
- Risk: Wasted CPU cycles
- Fix: Early-exit if source == target

**Gap 3.2: Sync vs async confusion**
- AVAudioConverter can work async, but plan isn't clear
- Missing: clear async/await usage
- Risk: Blocks main thread
- Fix: Explicit async throughout

### 4. CODE CLEANLINESS ISSUES

**Gap 4.1: Duplicate AudioConverter exists**
- `AudioConverter.swift` already does resampling
- Current plan creates new file
- Risk: Confusion, duplicate code
- Fix: Extend existing AudioConverter instead

**Gap 4.2: Out of place in VIPER structure**
- AudioService directory is correct
- Module/ subdirectory unnecessary
- Fix: Flat structure in AudioService/

---

## VERIFICATION STRATEGY

### QA Scenarios

1. **Internal mic recording**:
   - Tool: Bash (run app on simulator)
   - Start recording with internal mic selected
   - Expected: No crash, recording starts
   - Evidence: Xcode console log

2. **BLE mic recording**:
   - Connect BLE device, select as source
   - Start recording
   - Expected: Works (baseline verification)
   - Evidence: Recording file created

3. **Async conversion**:
   - After recording stops, check converted file exists
   - Expected: File exists within 5 seconds
   - Evidence: File in documents directory

4. **Sample rate detection**:
   - Log source rate before conversion
   - Expected: Log shows correct rate

5. **Skip when already 16kHz**:
   - Record at 16kHz source
   - Conversion should be skipped
   - Evidence: No conversion in logs

---

## EXECUTION STRATEGY

### Sequential Tasks

```
Task 1: InternalMicRecorder fix (foundation)
│   └── Use hardware format dynamically
│
Task 2: Extend existing AudioConverter
│   ├── Add sample rate detection
│   ├── Add 48kHz→16kHz conversion
│   └── Add skip-if-already-16kHz
│
Task 3: Wire to ML pipeline
│   └── Async conversion before ASR/MI
│
Task 4: Final verification
│   ├── Internal mic test
│   ├── BLE mic test (if available)
│   └── Full pipeline integration
```

---

## TODOs

### Task 1: Fix InternalMicRecorder ✅ DONE

**Files**:
- `Scribe/Services/AudioService/InternalMicRecorder.swift`
- `Scribe/Core/Config/AudioConfig.swift`

**What to do**:
1. Remove forced 16kHz format in line 116-124
2. Use `inputNode.outputFormat(forBus: 0)` as tap format
3. Record at whatever rate hardware provides (48kHz vs 16kHz)
4. Keep Opus encoder at 16kHz (for when conversion is added)
5. Update AudioConfig to track hardware rate

**Verify**: Build passes

---

### Task 2: Extend AudioConverter ✅ DONE

**File to modify**:
- `Scribe/Services/AudioService/AudioConverter.swift`

**What to add**:
1. `sampleRate(of: URL) -> Double` - detect source rate
2. `convertTo16kHzIfNeeded(url: URL) async throws -> URL` - smart conversion
3. Skip conversion if source is already 16kHz
4. Handle error cases with proper enum
5. Process in chunks for memory efficiency

**Implementation**:

```swift
// Extend existing AudioConverter.swift
public func sampleRate(of url: URL) throws -> Double {
    let file = try AVAudioFile(forReading: url)
    return file.processingFormat.sampleRate
}

public func convertTo16kHzIfNeeded(sourceURL: URL) async throws -> URL {
    let sourceRate = try sampleRate(of: sourceURL)
    
    // Already at target rate
    if sourceRate == targetSampleRate {
        ScribeLogger.debug("Source already at 16kHz, skipping conversion", category: .audio)
        return sourceURL
    }
    
    // Convert
    ScribeLogger.info("Converting \(Int(sourceRate))Hz → 16kHz", category: .audio)
    return try await convertTo16kHz(sourceURL: sourceURL)
}

// Error handling
public enum AudioConversionError: Error {
    case invalidSourceFormat
    case conversionFailed(Error?)
    case outputWriteFailed(Error?)
}
```

**Verify**: Test for 48kHz→16kHz passes

---

### Task 3: Wiring to ML Pipeline ✅ DONE

**Files**:
- `Scribe/Services/AudioService/InternalMicRecorder.swift` (update)
- `Scribe/Modules/RecordingListModule/Interactor/RecordingListInteractor.swift`

**What to do**:
1. After recording stops, get raw audio URL
2. Call AudioConverter.convertTo16kHzIfNeeded()
3. Pass converted URL to ML pipeline

**Pattern**:
```swift
let rawURL = recording.filePath

// Convert if needed (async)
let audioURL = try await audioConverter.convertTo16kHzIfNeeded(sourceURL: rawURL)

// ML pipeline uses audioURL
```

**Verify**: Build passes

---

### Task 4: Final Verification

**Verification Commands**:
```bash
xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
# Expected: BUILD SUCCEEDED
```

**QA Scenarios**:

1. **Internal mic test**:
   - Run app, select internal mic (or default)
   - Tap record button
   - Expected: Recording starts without crash

2. **BLE mic test** (if device available):
   - Connect BLE mic, select in DeviceSettings
   - Tap record button
   - Expected: Recording starts

3. **Conversion test**:
   - Record with internal mic
   - Stop recording
   - Wait 5 seconds
   - Check documents for converted file
   - Expected: File exists

4. **Skip test**:
   - Simulate 16kHz source
   - Verify no conversion in logs

---

## FINAL VERIFICATION WAVE

- [x] F1. Internal mic recording works

  Verify: Start recording, no crash in console
  Output: Recording file created

- [x] F2. Build passes

  Verify: xcodebuild build
  Output: BUILD SUCCEEDED

---

## SUCCESS CRITERIA

### Verification Commands
```bash
xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
# Expected: BUILD SUCCEEDED
```

### Final Checklist
- [ ] Internal mic records without crash
- [ ] BLE mic still works (if available)
- [ ] Async conversion runs correctly
- [ ] Skip when already 16kHz
- [ ] ML pipeline receives valid audio
- [ ] Build passes