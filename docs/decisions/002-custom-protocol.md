# ADR-002: Custom Protocol Over MSP

**Status:** Accepted  
**Date:** 2026-03-29  
**Deciders:** Project owner + Copilot design session

## Context

The Mary Sue Protocol (MSP) is a peer-to-peer protocol used by roleplaying
addons (TRP3, MyRolePlay, XRP) to exchange basic character profile fields.

MSP limitations (as documented by TRP3's own wiki):

- String-only values — no structured data without custom serialization.
- Each field identified by a 2-character code — limited extensible namespace.
- Poor performance with large payloads.
- Designed for interop between different RP addons.

Nagara's user-base is closed. All users run the same addon. MSP interop
provides no value and would constrain the data model.

## Decision

Nagara uses a **custom protocol** built on `C_ChatInfo.SendAddonMessage`
with the registered prefix `"Nagara"`.

### Wire Format

```
[protoVersion:1B][msgType:1B][seqNum:1B][totalChunks:1B][payload…]
```

- 4-byte header overhead per message.
- 251 usable payload bytes per chunk (255 byte message limit − 4 header).
- `protoVersion` enables graceful forward/backward compat.
- `msgType` enum: `PROFILE_REQUEST`, `PROFILE_RESPONSE`, `PROFILE_CHUNK`,
  `ROLL_RESULT`, `DM_EDIT`, `DM_ROLL_REQUEST`, `DM_EDIT_ACK`, etc.

### Transport

- Player-to-player: `"WHISPER"` distribution type.
- Broadcast (e.g., roll results): `"PARTY"` or `"RAID"`.

### Throttling

A hand-written FIFO queue with `C_Timer.After` drip respects
WoW's ~4 KB/s outgoing cap. No ChatThrottleLib needed.

## Consequences

- **Positive:** Full control over envelope format, message types,
  payload structure.
- **Positive:** Can transmit rich structured data (nested tables)
  via `Serialize.lua`.
- **Positive:** Protocol versioning from day one.
- **Negative:** No interop with TRP3/MRP/XRP. Acceptable — all users
  run Nagara.
- **Negative:** Must implement chunking and reassembly ourselves.
  Estimated ~60 LOC.
