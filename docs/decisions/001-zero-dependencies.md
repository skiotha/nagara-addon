# ADR-001: Zero External Dependencies

**Status:** Accepted  
**Date:** 2026-03-29  
**Deciders:** Project owner + Copilot design session

## Context

WoW addons commonly use shared libraries (Ace3, LibStub, LibCompress,
ChatThrottleLib, LibMSP) to avoid reinventing common functionality.
These libraries introduce load-order dependencies, version-mismatch bugs
between addons, and maintenance burden when upstream changes.

Nagara has a closed, small user-base (~5–10 people). There is exactly one
addon in this ecosystem, so library sharing between addons is irrelevant.

## Decision

Nagara will carry **zero external library dependencies**.

All required utilities are implemented in `Util/`:

| Need                         | DIY module      | Approx. size |
| ---------------------------- | --------------- | ------------ |
| Pub/sub events               | `Callbacks.lua` | ~40 LOC      |
| Table ↔ string serialization | `Serialize.lua` | ~150 LOC     |
| Base64 encode/decode         | `Base64.lua`    | ~80 LOC      |
| Message chunking             | `Chunker.lua`   | ~60 LOC      |
| Send-rate throttling         | `Throttle.lua`  | ~50 LOC      |

Compression (LibCompress) is **not needed**: charsheets are <4 KB,
well within WoW's outgoing throughput budget.

## Consequences

- **Positive:** Full control over every line. No version conflicts.
  No load-order issues. Smaller addon footprint.
- **Positive:** Every utility is testable with `busted` outside WoW.
- **Negative:** Must write and maintain ~380 lines of utility code.
  Acceptable for this project size.
- **Negative:** If a future feature needs heavy compression or
  cryptography, we may revisit. At that point we can vendor a single
  library rather than adopt the full Ace3 stack.
