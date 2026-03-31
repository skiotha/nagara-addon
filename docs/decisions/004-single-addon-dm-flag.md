# ADR-004: Single Addon with DM Mode Flag

**Status:** Accepted  
**Date:** 2026-03-29  
**Deciders:** Project owner + Copilot design session

## Context

The addon needs two logical modes: **Player** (default) and **DM** (can edit other characters, request dice rolls). Two distribution strategies were considered:

1. **Two separate addon folders** with distinct `.toc` files.
2. **Single addon** with a runtime mode flag.

## Decision

Single addon with `NagaraDB.dmMode` flag.

- DM source files (`DM/DMPanel.lua`, `DM/DMComm.lua`) are always loaded via the TOC but their UI and comm handlers only activate when `NagaraDB.dmMode == true`.
- DM mode is toggled via `/nagara dm` (or another simple command).
- The DM is a single known person; the overhead of the extra Lua files is negligible.

### Authorization

- DM commands received by other players are validated against a `DM_NAMES` allow-list in `Constants.lua`.
- Format: `{ "Charactername-Realm" = true }`.
- Not cryptographically secure — appropriate for a trust-based group.

## Consequences

- **Positive:** Single TOC, single folder, single release zip.
- **Positive:** No conditional file-loading gymnastics.
- **Negative:** DM code ships to all players (a few KB — negligible).
- **Negative:** Anyone who edits their SavedVariables can set `dmMode = true`. Not a real threat in a friends-only group, and the receiver-side allow-list still blocks unauthorized edits.
