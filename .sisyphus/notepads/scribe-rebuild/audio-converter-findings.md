# Audio Converter Implementation - Findings & Analysis

## Date
2026-04-12

## The Issue

**Crash on recording start** when using internal microphone:

```
Audio route changed - reason: categoryChange
Audio session configured - category: playAndRecord, sampleRate: 16000.0
OpusEncoder initialized - 16000Hz, 1ch, frameSize: 320
           AVAEUtility.mm:176   Format mismatch: input hw <AVAudioFormat 0x105b75680:  1 ch,  48000 Hz, Float32>, client format <AVAudioFormat 0x105b756d0:  1 ch,  16000 Hz, Float32>
*** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'Failed to create tap due to format mismatch, <AVAudioFormat 0x105b756d0:  1 ch,  16000 Hz, Float32>'
```

## Root Cause Analysis

### The Problem
`InternalMicRecorder.swift` line 135 tries to install a tap with **16kHz format**:
```swift
inputNode.installTap(onBus: 0, bufferSize: ..., format: targetFormat) { ... }
```

Where `targetFormat` is 16kHz (from `AudioConfig.sampleRate = 16000`).

But the internal iOS microphone hardware runs at **48kHz natively**. AVAudioEngine cannot create a format conversion tap at install time - it expects the tap format to match hardware.

### Sample Rate Mismatch

| Component | Sample Rate | Notes |
|-----------|------------|-------|
| AudioConfig | 16kHz | Target for Opus/MI pipeline |
| Internal iOS Mic | 48kHz | Native hardware rate |
| Bluetooth Mic | varies | Typically 16kHz, but depends on device |

### Why Bluetooth Works (Expected)
The crash didn't happen with Bluetooth mic because BLE audio devices typically run at 16kHz or can negotiate down to match. The internal mic is what's crashing.

## Code Locations

### Primary File
- `Scribe/Services/AudioService/InternalMicRecorder.swift`
  - Lines 105-146: `setupAudioEngine()` - where crash occurs
  - Line 113: Gets hardware format
  - Line 116-124: Creates 16kHz target format
  - Line 135: **Installs tap with WRONG format** ← CRASH HERE

### Configuration
- `Scribe/Core/Config/AudioConfig.swift`
  - Line 6: `sampleRate: Double = 16_000`

### Opus Encoder
- `Scribe/Services/AudioService/OpusEncoder.swift`
  - Line 13: `sampleRate: Int32 = 16000` - accepts 16kHz only

## Solution Requirements

### Key Insight
**Conversion does NOT need to be real-time.** The ML pipeline processes recordings in batches asynchronously, so a few seconds of latency is acceptable.

### Architecture

```
Recording (any rate: 16kHz/44.1kHz/48kHz)
         ↓
    Raw CAF file
         ↓
    Background async conversion (48kHz → 16kHz)
         ↓
    Converted PCM → Opus encoder → ASR/MI pipeline
```

This means:
- ✅ No complex real-time streaming conversion needed
- ✅ Can use simpler batch processing APIs
- ✅ AVAudioConverter in offline mode (for file-based conversion)
- ✅ Can process with slight delay

### Implementation Options

**Option A: Post-recording conversion (RECOMMENDED)**
1. Record at whatever rate hardware provides (48kHz internal, 16kHz BLE)
2. Save raw audio
3. Convert to 16kHz in background before passing to ML
4. Simple, robust, no real-time complexity

**Option B: Real-time with AVAudioConverter**
1. Install tap at hardware rate
2. Convert each buffer with AVAudioConverter in callback
3. More complex, potential for buffer underruns

### Recommendation: Option A

Use post-recording conversion:

1. **Modify `InternalMicRecorder`** to install tap at hardware rate (not 16kHz)
2. **Record at native rate** (48kHz for internal, whatever BLE provides)
3. **Add async converter** to convert to 16kHz before ML pipeline
4. **Minimal code change** - most complexity is in converter itself

### Files to Modify

1. `Scribe/Services/AudioService/InternalMicRecorder.swift` - remove forced 16kHz format
2. `Scribe/Core/Config/AudioConfig.swift` - adjust or add hardware rate tracking
3. New: `Scribe/Services/AudioService/AudioSampleRateConverter.swift` - batch converter for 48kHz → 16kHz
4. Update recording consumer to run conversion before ML pipeline

### Verification Strategy

1. Record with internal mic → app doesn't crash
2. Record with BLE mic → app doesn't crash  
3. Both recordings convert to 16kHz correctly
4. ML pipeline receives valid 16kHz audio

## Console Log Reference

```
Audio route changed - reason: categoryChange        ← Audio session activated
Audio session configured - category: playAndRecord, sampleRate: 16000.0  ← session configured
OpusEncoder initialized - 16000Hz, 1ch, frameSize: 320  ← encoder created OK
Format mismatch: input hw <...48000Hz...>, client format <...16000Hz...>  ← MISMATCH
Failed to create tap due to format mismatch  ← CRASH
```

## Next Steps for Plan

1. Create implementation plan for Option A (post-recording conversion)
2. Write AudioSampleRateConverter using AVAudioConverter in offline mode
3. Update InternalMicRecorder to use hardware rate
4. Wire up conversion before ML pipeline input
5. Verify with both internal and BLE microphones

---

## GAP ANALYSIS SUMMARY

### Fixed Issues (from analysis):

1. **VIPER unnecessary**: Use plain class pattern (matches OpusEncoder, AudioConverter)
2. **Sample rate detection**: Added - check if already 16kHz before converting
3. **Error handling**: Added - proper error enum
4. **Skip unnecessary conversion**: Will skip if source already 16kHz
5. **Extend existing AudioConverter**: Instead of creating new file

### Key Changes from Original Plan:

| Original | Updated |
|----------|---------|
| New VIPER module | Extend existing AudioConverter |
| Always convert | Skip if already 16kHz |
| No error handling | Proper error enum |
| Hardcoded path | Async/await |

### Files to Modify (simplified):

1. `Scribe/Services/AudioService/InternalMicRecorder.swift`
2. `Scribe/Services/AudioService/AudioConverter.swift` (extend)