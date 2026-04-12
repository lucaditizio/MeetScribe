# SwiftUI-Native VIPER Migration Plan

## TL;DR

> Fix 6 broken Views that use Classical VIPER pattern (incompatible with SwiftUI) by migrating to SwiftUI-native pattern with `@Bindable presenter`.
> 
> Deliverables: 6 Views updated to use `@Bindable var presenter` + `@Observable` Presenter state
> Estimated Effort: Medium
> Parallel Execution: YES - 2 waves of 3 views each

---

## Context

### Problem
SwiftUI Views are `structs`, but VIPER protocols require `class` (AnyObject). This breaks Classical VIPER display method pattern:
- Presenter tries to call `view?.displayDevices()` but `view` is nil
- Struct cannot conform to class-only protocol
- Result: UI never updates when data changes

### Solution
Use SwiftUI-native pattern:
- `@Bindable var presenter: SomePresenter` - SwiftUI observes Presenter's `@Observable` state
- Read `presenter.state.xxx` directly in body
- User actions call `presenter.didTapXxx()`

### Already Working
- AgentGeneratingView (correct from start)
- DeviceSettingsView (just fixed)

### Needs Fix (6 views)
- RecordingListView
- RecordingDetailView
- TranscriptTabView
- SummaryTabView
- MindMapView
- WaveformPlaybackView

---

## Work Objectives

### Core Objective
Migrate 6 Views from broken Classical VIPER to working SwiftUI-native VIPER.

### Concrete Deliverables
- [ ] 6 View files updated with `@Bindable var presenter`
- [ ] 6 AppAssembly factory methods updated
- [ ] Build passes after each view fix
- [ ] All views respond to dynamic data updates

### Must Have
- Each view uses `@Bindable var presenter: SomePresenter`
- Body reads `presenter.state.xxx` directly
- User actions call `presenter.didXxx()` methods

### Must NOT
- Keep `@State private var state` patterns
- Try to wire display methods (they can't work with structs)
- Change Presenter/Interactor business logic

---

## Verification Strategy

Every task MUST include QA scenarios:

1. **Build verification**: `xcodebuild -scheme Scribe build`
2. **Static display**: View renders initial data
3. **Dynamic update** (per view): Trigger data change, verify UI updates

---

## Execution Strategy

### Wave 1 (Parallel - 3 views)
- Task 1: RecordingListView
- Task 2: RecordingDetailView  
- Task 3: TranscriptTabView

### Wave 2 (Parallel - 3 views)
- Task 4: SummaryTabView
- Task 5: MindMapView
- Task 6: WaveformPlaybackView

---

## TODOs

### Wave 1

- [x] 1. RecordingListView → SwiftUI-native VIPER

  **Files**: 
  - `Scribe/Modules/RecordingListModule/View/RecordingListView.swift`
  - `Scribe/App/AppAssembly.swift` (line ~19)

  **Current State** (GAP FOUND):
  - Already has `@Bindable public var router: RecordingListRouter`
  - Still has `@State private var state: RecordingListState`
  - Has both router AND state - needs to ADD presenter

  **What to do**:
  1. ADD `@Bindable var presenter: RecordingListPresenter` (keep existing router)
  2. Remove `@State private var state` (it's broken anyway)
  3. Change init from `init(output: RecordingListViewOutput, router: RecordingListRouter)` to `init(presenter: RecordingListPresenter, router: RecordingListRouter)`
  4. Replace all `state.xxx` with `presenter.state.xxx`
  5. Replace all `output.didTapXxx()` with `presenter.didTapXxx()`
  6. Keep `@Bindable public var router` for navigation
  7. Update AppAssembly: add presenter parameter to init

  **Verify**: `xcodebuild -scheme Scribe build`

- [x] 2. RecordingDetailView → SwiftUI-native VIPER

  **Files**:
  - `Scribe/Modules/RecordingDetailModule/View/RecordingDetailView.swift`
  - `Scribe/App/AppAssembly.swift` (line ~29)

  **What to do**:
  1. Replace `@State private var state` with `@Bindable var presenter: RecordingDetailPresenter`
  2. Change init to `init(presenter: RecordingDetailPresenter)`
  3. Replace all `state.xxx` with `presenter.state.xxx`
  4. Replace all `output.didTapXxx()` with `presenter.didTapXxx()`
  5. Keep `@State private var selectedTabBinding` for tab selection (convert to computed if needed)
  6. Update AppAssembly: change `RecordingDetailView(output: presenter)` to `RecordingDetailView(presenter: presenter)`

  **Verify**: `xcodebuild -scheme Scribe build`

- [x] 3. TranscriptTabView → SwiftUI-native VIPER

  **Files**:
  - `Scribe/Modules/TranscriptModule/View/TranscriptTabView.swift`
  - `Scribe/App/AppAssembly.swift` (line ~47)

  **What to do**:
  1. Replace `@State internal var state` with `@Bindable var presenter: TranscriptPresenter`
  2. Change init to `init(presenter: TranscriptPresenter)`
  3. Replace all `state.xxx` with `presenter.state.xxx`
  4. Replace all `output.didTapXxx()` with `presenter.didTapXxx()`
  5. Update AppAssembly: change `TranscriptTabView(output: presenter)` to `TranscriptTabView(presenter: presenter)`

  **Verify**: `xcodebuild -scheme Scribe build`

### Wave 2

- [x] 4. SummaryTabView → SwiftUI-native VIPER

  **Files**:
  - `Scribe/Modules/SummaryModule/View/SummaryTabView.swift`
  - `Scribe/App/AppAssembly.swift` (line ~56)

  **What to do**:
  1. Replace `@State internal var state` with `@Bindable var presenter: SummaryPresenter`
  2. Change init to `init(presenter: SummaryPresenter)`
  3. Replace all `state.xxx` with `presenter.state.xxx`
  4. Replace all `output.didTapXxx()` with `presenter.didTapXxx()`
  5. Update AppAssembly: change `SummaryTabView(output: presenter)` to `SummaryTabView(presenter: presenter)`

  **Verify**: `xcodebuild -scheme Scribe build`

- [x] 5. MindMapView → SwiftUI-native VIPER

  **Files**:
  - `Scribe/Modules/MindMapModule/View/MindMapView.swift`
  - `Scribe/App/AppAssembly.swift` (line ~65)

  **What to do**:
  1. Replace `@State private var state` with `@Bindable var presenter: MindMapPresenter`
  2. Change init to `init(presenter: MindMapPresenter)`
  3. Replace all `state.xxx` with `presenter.state.xxx`
  4. Replace all `output.didTapXxx()` with `presenter.didTapXxx()`
  5. Update AppAssembly: change `MindMapView(output: presenter)` to `MindMapView(presenter: presenter)`

  **Verify**: `xcodebuild -scheme Scribe build`

- [x] 6. WaveformPlaybackView → SwiftUI-native VIPER

  **Files**:
  - `Scribe/Modules/WaveformPlaybackModule/View/WaveformPlaybackView.swift`
  - `Scribe/App/AppAssembly.swift` (line ~38)

  **What to do**:
  1. Replace `@State private var state` with `@Bindable var presenter: WaveformPlaybackPresenter`
  2. Change init to `init(presenter: WaveformPlaybackPresenter)`
  3. Replace all `state.xxx` with `presenter.state.xxx`
  4. Replace all `output.didTapXxx()` with `presenter.didTapXxx()`
  5. Update AppAssembly: change `WaveformPlaybackView(output: presenter)` to `WaveformPlaybackView(presenter: presenter)`

  **Verify**: `xcodebuild -scheme Scribe build`

---

## Final Verification Wave

- [x] F1. All 8 views use SwiftUI-native pattern

  Verify: Check each View file has `@Bindable var presenter` and no `@State private var state`
  Output: List of views with pattern used

- [x] F2. Build passes

  Verify: `xcodebuild -scheme Scribe build`
  Output: BUILD SUCCEEDED

---

## Success Criteria

### Verification Commands
```bash
xcodebuild -scheme Scribe -destination 'platform=iOS Simulator,name=iPhone 15 Plus' build
# Expected: BUILD SUCCEEDED
```

### Final Checklist
- [ ] All 8 views have `@Bindable var presenter`
- [ ] No views use `@State private var state` pattern
- [ ] Build passes
- [ ] Debug-history updated