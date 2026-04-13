# ML Pipeline Remaining Issues & Action Plan (Bug 27)

## ✅ COMPLETED

### Phase 1: Fix Audio Loading (Use AVFoundation instead of raw Data)
- **File:** `InferencePipeline.swift`
- **Action:** Modified `loadAudioData()` to use `AudioConverter.convertCAFToPCMForASR(url:)` which properly loads audio via AVFoundation instead of raw Data. This extracts clean Float32 PCM samples without CAF headers.
- **Status:** DONE - Build succeeded

### Phase 2: Save the Pipeline Results to the Recording
- **Files:** `AgentGeneratingInteractor.swift`, `Recording.swift`
- **Action:** 
    - Added `summary` relationship to `Recording` model
    - After pipeline returns, create `Transcript` and `MeetingSummary` objects and attach to recording
    - Call `recordingRepository.update()` to save to database
- **Status:** DONE - Build succeeded

### Phase 3: Auto-Dismiss the Generating UI on Success
- **File:** `AgentGeneratingView.swift`
- **Action:** Added `.onChange(of: presenter.state.progress)` that triggers `dismiss()` when progress >= 1.0 and no error
- **Status:** DONE - Build succeeded

---

## 🚀 Original Execution Plan (for reference)

### Phase 1: Fix Audio Loading (Use AVFoundation instead of raw Data)
*   **File:** `Scribe/Services/MLService/Pipeline/InferencePipeline.swift` or `AudioConverter.swift`
*   **Action:** Modify how audio is passed to the pipeline. Instead of passing raw file `Data` which includes headers, load the file dynamically via `AVAudioFile`. Alternatively, use `FluidAudio`'s `AudioConverter.resampleAudioFile(url)` or properly extract AVAudioPCMBuffer so that the ASR and Language Detection services receive clean, resampled Float32 PCM arrays without file headers.

### Phase 2: Save the Pipeline Results to the Recording
*   **File:** `Scribe/Modules/AgentGeneratingModule/Interactor/AgentGeneratingInteractor.swift`
*   **Action:** 
    *   After `let result = try await self.inferencePipeline.process(recording: recording)` returns the `(Transcript, MeetingSummary)` tuple, attach these objects to the `recording` model.
    *   Call `try await recordingRepository.update(recording)` so the database actually saves the generated data.
    *   Once the sheet dismisses, the `RecordingDetailView` will then display the correct transcript and summary since the database is updated.

### Phase 3: Auto-Dismiss the Generating UI on Success
*   **File:** `Scribe/Modules/AgentGeneratingModule/View/AgentGeneratingView.swift`
*   **Action:** Add an `.onChange(of: presenter.state.isProcessing)` (or check for `progress == 1.0` and `!isProcessing`) that triggers `dismiss()` when the pipeline reports completion.

*(Please execute this plan meticulously!)*
