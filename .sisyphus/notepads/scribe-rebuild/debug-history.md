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

### Bug 5: Hardcoded Recording Source
**Issue:** StartRecording used hardcoded `.rawInternal` regardless of external mic connection
**Root Cause:** DeviceConnectionManager was not injected into RecordingListInteractor
**Fix Applied (2026-04-12):**
- DeviceConnectionManagerProtocol: Added `isConnected` property
- DeviceConnectionManager.swift: Implemented `isConnected` computed property
- RecordingListInteractor: Injected DeviceConnectionManager, now checks `deviceConnectionManager.isConnected`
- RecordingSource selection now dynamic: `.rawBle` if connected, `.rawInternal` otherwise
- Updated RecordingListAssembly and AppAssembly to pass DeviceConnectionManager

### Bug 6: Duplicate Modules Folder
**Issue:** Root-level `Modules/` folder with duplicate files (TranscriptAssembly, WaveformPlaybackAssembly, etc.)
**Root Cause:** Subagent placed files in wrong location during Task 35.2 wiring
**Fix Applied (2026-04-12):**
- Deleted entire `/Modules` folder at project root
- Verified build still succeeds with `Scribe/Modules/` (correct location)

### Bug 7: Build Warnings - High Priority Fixes
**Issue:** 4 high-priority warnings (1 critical, 3 deprecated)
**Fix Applied (2026-04-12):**
1. **Critical**: InternalMicRecorder.swift:71 - main actor isolation
   - Wrapped `impactOccurred()` in `await MainActor.run { }`
2. **Deprecated**: AudioPlayer.swift:55 - allowBluetooth
   - Changed to `.allowBluetoothHFP`
3. **Deprecated**: InternalMicRecorder.swift:90 - allowBluetooth
   - Changed to `.allowBluetoothHFP`
4. **Deprecated**: WaveformAnalyzer.swift:24 - AVAsset(url:)
   - Changed to `AVURLAsset(url:)`

**Remaining warnings (lower priority):**
- AgentGeneratingInteractor module import warnings (3x)

### Bug 8: Bluetooth Not Working - Missing Privacy Keys
**Issue:** Scan button does nothing, console shows "Bluetooth not powered on", Bluetooth not in iOS Settings for app
**Root Cause:** Info.plist missing iOS Bluetooth privacy keys - without these, iOS denies Bluetooth access silently
**Fix Applied (2026-04-12):**
- Added to Scribe/Info.plist:
  - `NSBluetoothAlwaysUsageDescription` - "MeetScribe needs Bluetooth to connect to external recording devices."
  - `NSBluetoothPeripheralUsageDescription` - "MeetScribe needs Bluetooth to connect to external recording devices."
**Expected Result:** iOS will now prompt user for Bluetooth permission on first scan attempt

### Bug 9: DeviceSettings View Not Updating (State Sync Issue)
**Issue:** Bluetooth scanning works (console shows discovered devices) but UI shows "No devices found"
**Root Cause:** DeviceSettingsView created local `state` property without @State wrapper - SwiftUI couldn't observe Presenter state changes
**Hypothesis:** Only DeviceSettingsView had this bug among all 10 views - others use @State or @Bindable correctly
**Fix Applied (2026-04-12):**
- DeviceSettingsView.swift: Added `@State` wrapper to state property
- Added display methods (displayDevices, displayConnectionState, displayError) to View
- DeviceSettingsPresenter.swift: Changed view to `public weak var view: (any DeviceSettingsViewInput)?`
- AppAssembly.swift: Wire view to presenter after creating View

**Architecture now:**
- View has @State for local rendering
- Presenter calls view?.displayDevices() when data changes
- View updates local @State in display methods
- SwiftUI triggers redraw

### Bug 10: SwiftUI-native VIPER for DeviceSettingsView
**Issue:** Bluetooth scan UI not updating - display methods couldn't be wired (struct vs class-only protocol)
**Root Cause:** Classical VIPER display method pattern incompatible with SwiftUI Views (structs can't conform to AnyObject protocols)
**Fix Applied (2026-04-12):**
- Rewrote DeviceSettingsView to use SwiftUI-native pattern:
  - `@Bindable var presenter: DeviceSettingsPresenter` - SwiftUI observes Presenter's @Observable state
  - Direct access to `presenter.state.discoveredDevices` in body
  - Removed display methods and @State wrapper
- Updated AppAssembly to pass presenter directly to View
- Pattern now matches AgentGeneratingView (the only view using correct pattern)

**Key insight:** The codebase mixed classical VIPER (display methods) with SwiftUI-native (@Bindable). AgentGeneratingView was the only correct implementation. DeviceSettingsView now follows suit.

### Bug 9: Internal Mic Recording Crash - Format Mismatch
**Issue:** App crashes on recording start with internal mic:
```
Format mismatch: input hw <...48000Hz...>, client format <...16000Hz...>
Failed to create tap due to format mismatch
```
**Root Cause:** InternalMicRecorder tried to install AVAudioEngine tap at 16kHz, but internal iOS mic runs at 48kHz native. AVAudioEngine can't bridge at tap-install time.
**Fix Applied (2026-04-12):**
- Rewrote InternalMicRecorder to use AVAudioRecorder at 48kHz AAC (.m4a) - matching original Scribe
- AudioConverter extended to accept both .caf and .m4a input, output .caf with _16kHz suffix
- RecordingListInteractor wired to convert after recording stops

### Bug 10: UI Doesn't Update After Recording Starts
**Issue:** Recording starts but UI shows start button (not stop button)
**Root Cause:** No state sync between InternalMicRecorder and UI - presenter didn't know recording started
**Fix Applied (2026-04-12):**
- RecordingListInteractor exposes isRecordingPublisher (from AudioRecorderProtocol)
- RecordingListInteractorInput protocol updated to include isRecordingPublisher
- RecordingListPresenter subscribes to recording state, updates state.isRecording

### Bug 11: Recording Not Showing in UI
**Issue:** Recording starts/stops/converts, but RecordingListView doesn't show the file
**Root Cause:** Recording created with original .m4a path BEFORE conversion, only local object updated
**Fix Applied (2026-04-12):**
- RecordingListInteractor.stopRecording(): Create Recording AFTER conversion with converted .caf path
- Save converted Recording to repository so UI fetches correct .caf path

### Bug 12: Recording Not Showing After Save
**Issue:** Recording shows in console log but UI still empty
**Root Cause:** Race condition - fetch runs async but UI updates before save completes
**Fix Applied (2026-04-12):**
- stopRecording() now calls fetchAll() immediately after save() to ensure data is available
- Passes fresh recordings directly to didObtainRecordings()

---

## Files Modified in This Session

### Audio Service
- `Scribe/Services/AudioService/InternalMicRecorder.swift` - AVAudioRecorder @ 48kHz AAC
- `Scribe/Services/AudioService/AudioConverter.swift` - accepts .caf/.m4a, outputs .caf

### RecordingListModule
- `Scribe/Modules/RecordingListModule/Interactor/RecordingListInteractor.swift` - isRecordingPublisher, fix stopRecording(), await fetch after save
- `Scribe/Modules/RecordingListModule/Interactor/RecordingListInteractorInput.swift` - protocol updated
- `Scribe/Modules/RecordingListModule/Presenter/RecordingListPresenter.swift` - subscribes to recording state