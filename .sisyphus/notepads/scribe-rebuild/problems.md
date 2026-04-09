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
