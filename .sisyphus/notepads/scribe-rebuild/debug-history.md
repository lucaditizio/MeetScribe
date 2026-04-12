# Debug History - MeetScribe

## Entry Format
- Date
- Bug/Issue Description
- Root Cause
- Fix Applied

---

## 2026-04-12

### Bug 1: Record Button Design
**Issue:** Record button had white core instead of being fully red
**Root Cause:** Inner white circle was added in UI implementation
**Fix:** Removed inner white circle, added white mic.fill icon (bold, 28pt) per original Scribe design

### Bug 2: App Icon Missing
**Issue:** App had no icon
**Root Cause:** Assets.xcassets not set up in MeetScribe project
**Fix:** Copied AppIcon.appiconset from original Scribe project

### Bug 3: Mic Indicator Position
**Issue:** Mic source indicator was left-aligned
**Root Cause:** Layout in bottomBarView used HStack with Spacer
**Fix:** Changed to VStack to center indicator above record button

### Bug 4: Button Wiring - Navigation Errors
**Issue:** 
- Toolbar `mic.badge.plus` opens AgentGenerating (ML pipeline) instead of DeviceSettings
- Toolbar `antenna.radiowaves.left.and.right` correctly opens DeviceSettings
- Bottom RecordButtonView opens AgentGenerating instead of starting recording

**Root Cause:** 
- Task 35.2 (wiring) incorrectly wired `didTapRecord()` to `router.openAgentGenerating()`
- Plan specified single toolbar button (`mic.badge.plus`) should open DeviceSettings
- AgentGenerating is for post-recording ML processing, not for starting recordings

**Proposed Fix:**
- Toolbar: Remove `antenna.radiowaves.left.and.right` button
- Toolbar: Change `mic.badge.plus` action from `didTapRecord()` to `didTapSettings()`
- Bottom RecordButtonView: Wire `didTapRecord()` to actually start recording (not AgentGenerating)

**Fix Applied (2026-04-12):**
- RecordingListView.swift: Removed leading toolbar button, single toolbar button now calls `didTapSettings()`
- RecordingListViewOutput.swift: No changes needed
- RecordingListInteractorInput.swift: Added `startRecording()` and `stopRecording()` methods
- RecordingListInteractorOutput.swift: Added `didStartRecording()` and `didStopRecording(result:)` methods
- RecordingListInteractor.swift: Implemented start/stop recording using audioRecorder service
- RecordingListPresenter.swift: Updated to implement RecordingListInteractorOutput, didTapRecord now toggles recording state
- RecordingListAssembly.swift: Added audioRecorder parameter to build()
- AppAssembly.swift: Passed audioRecorder to RecordingListAssembly.build()

**Current State:**
- Toolbar button (mic.badge.plus) → opens DeviceSettings ✓
- Bottom RecordButtonView → starts/stops actual recording ✓
- AgentGenerating remains available for post-recording ML processing