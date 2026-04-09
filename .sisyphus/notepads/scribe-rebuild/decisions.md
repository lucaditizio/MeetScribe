# Scribe Rebuild - Decisions

## Architecture Decisions

### VIPER Module Structure
- Every module has Assembly, Interactor, Presenter, Router, View
- Interactor holds NO state - only dependencies and weak output
- View is STRICTLY passive - no business logic
- Router handles ALL navigation
- ModuleInput/ModuleOutput for inter-module communication

### Audio Strategy
- Unified Opus format for both internal mic and BLE
- Internal mic: Record at 48kHz AAC, convert to Opus/CAF
- BLE: Direct Opus decode to Float32 PCM at 16kHz

### ML Pipeline Memory Management
- Sequential model loading (never coexist in RAM)
- Pattern: load → run → nil
- Peak RAM target: <2GB on 6GB device

### BLE SLink Protocol
- Preserve exact proprietary logic - copy, don't modify
- Hardcoded serial "129950" for now
- Dynamic extraction architecture prepared for later

## Open Questions / Decisions
- None yet

## Changes from Original
- Eliminated triple-nested Scribe/Scribe/Scribe structure
- Replaced all print statements with ScribeLogger
- Fixed empty catch blocks (line 139 in AudioRecorder.swift)
- Unified audio format to Opus/CAF
- Added micSource field to Recording model

## Deviations from Plan (Documented)

### RecordingSource Enum Cases (Fix 5)
**Plan specified:** `case internal = "internal"`, `case ble = "ble"`
**Actual implementation:** `case rawInternal = "internal"`, `case rawBle = "ble"`
**Reason:** Swift reserves `internal` as a keyword, cannot use as enum case name
**Workaround:** Used `rawInternal`/`rawBle` as case names with correct raw values
**Impact:** Minimal - raw values match plan, only case names differ
**Files affected:** RecordingSource.swift, Recording.swift, VIPERProtocolTests.swift, RecordingTests.swift
