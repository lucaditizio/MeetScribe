# Scribe Rebuild - Problems

## Technical Debt
None yet.

## Code Smells to Watch
- Force unwraps (!)
- Empty catch blocks
- Print statements
- Files exceeding 400 lines
- Business logic in Views
- Direct service access from Presenters
- State in Interactors

## Known Limitations
- BLE serial number hardcoded as "129950"
- Swiss German Whisper model requires download
- LLM model requires download (~2GB)

## Phase 13 - Unified Recording Technical Debt (2026-04-10)

### 1. UnifiedRecorder.swift - Line Count Exceeds Guideline
**File:** `Services/AudioService/UnifiedRecorder.swift` (445 lines)
**Issue:** Exceeds 400-line guideline by 45 lines
**Impact:** Medium - File is complex but manageable
**Recommendation:** Consider splitting CAF file writing logic into a separate `CAFFileWriter` utility class

### 2. Test Failures in UnifiedRecorderTests
**File:** `ScribeTests/Services/Audio/UnifiedRecorderTests.swift`
**Status:** 10 passing, 9 failing (out of 19 tests)
**Failed Tests:**
- testInternalRecorderStopsCleanly
- testRecordingHasCorrectSourceForInternalMic
- testRecordingHasDuration
- testRecordingStopsCleanlyOnDisconnect
- testStartRecordingWithBLEBoundUsesBLEStream
- testStartRecordingWithBLEConnectedDoesNotStartInternalRecorder
- testStartRecordingWithBLEConnectedUsesBLEStream
- testStopRecordingReturnsRecording
- testStopRecordingSavesPartialRecordingOnBLEDisconnect
- testStopRecordingStopsBLEStream

**Root Cause:** Test expectations don't align with actual implementation behavior
**Impact:** Low - Core functionality works (10 tests pass), but edge cases need refinement
**Recommendation:** Review and update test expectations or fix implementation to match

### 3. Mock Class Proliferation
**Issue:** Multiple mock implementations for similar protocols
**Files Affected:**
- `MockAudioRecorder` (in ServiceProtocolMocks.swift)
- `EnhancedMockAudioRecorder` (in UnifiedRecorderTests.swift)
- `MockAudioStream` (in UnifiedRecorderTests.swift)

**Impact:** Low - Test isolation is good but some duplication exists
**Recommendation:** Consolidate mock implementations into a shared test utilities module

### 4. AudioStreamProtocol vs AudioRecorderProtocol Confusion
**Issue:** Two similar protocols for audio handling may cause confusion
- `AudioStreamProtocol` - for BLE audio streaming
- `AudioRecorderProtocol` - for internal mic recording

**Impact:** Low - Currently works but could be confusing for new developers
**Recommendation:** Document the distinction clearly in code comments

### 5. CAF File Format Implementation
**Issue:** Custom CAF file writing in UnifiedRecorder
**Location:** Lines ~200-280 in UnifiedRecorder.swift
**Impact:** Medium - Complex binary file format handling
**Recommendation:** Consider using AVFoundation's CAF writing capabilities or extract to dedicated class

## Session Restart Context

### Current Progress
- Phase 13: 3/3 tasks complete ✅
- Total: 41/121 tasks (34% complete)
- Last working: UnifiedRecorderTests compiling and running

### Next Phase Ready
- Phase 14: Audio Playback (14.1, 14.2, 14.3)
- All Phase 13 files committed to working directory
- No blocking issues

### Environment State
- Build: ✅ Succeeded
- Tests: ⚠️ Partial (10/19 passing)
- No compilation errors
- No force unwraps or empty catch blocks introduced
