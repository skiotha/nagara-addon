# ADR-009: Two-Addon Split (Player + DM)

**Status:** Accepted  
**Date:** 2026-04-09  
**Deciders:** Project owner + Copilot design session  
**Supersedes:** [ADR-004](004-single-addon-dm-flag.md)

## Context

ADR-004 decided on a single addon with a `NagaraDB.dmMode` runtime flag. Upon reconsideration, two concerns emerged:

1. **Privacy.** The player addon is distributed via a public GitHub repository. DM-specific code (character editing, roll requests) should remain private — visible only to the project owner who is also the sole DM.
2. **Separation of concerns.** Player features are released to the group; DM features exist in a single copy on the DM's personal machine.

GitHub does not support per-folder visibility. Branches, `.gitignore`, and `git-crypt` all carry accident risk (one wrong `git add .` leaks DM code). A structural boundary — two separate repositories — eliminates the risk entirely.

## Decision

Split into two WoW addons distributed from two separate repositories:

| | **Nagara** (player) | **NagaraDM** (DM) |
|---|---|---|
| Repository | `skiotha/nagara-addon` (public) | `skiotha/nagara-dm` (private) |
| Addon folder | `Interface/AddOns/Nagara/` | `Interface/AddOns/NagaraDM/` |
| TOC dependency | — | `## Dependencies: Nagara` |
| SavedVariables | `NagaraDB` | `NagaraDMDB` |
| GitHub Releases | Yes (zip for all players) | No (installed manually by DM) |

### Namespace Bridge

The player addon exposes its internal namespace as a single global:

```lua
-- Nagara.lua
NagaraNS = ns
```

The DM addon consumes it:

```lua
-- DM/DMPanel.lua
local ns = NagaraNS
```

WoW's `## Dependencies: Nagara` directive guarantees Nagara loads first, so `NagaraNS` is available when DM files execute.

### Protocol Message Types

DM-related message type enum values (`DM_EDIT = 0x20`, `DM_EDIT_ACK = 0x21`, `DM_ROLL_REQUEST = 0x22`) remain defined in the player addon's `Comm/Protocol.lua`. This is necessary because the **player** must know how to handle incoming DM messages (receiver-side validation + response).

The DM addon registers the **sending** handlers; the player addon registers the **receiving** handlers.

### Authorization

`DM_NAMES` allow-list stays in the player addon's `Constants.lua`. When a player receives a `DM_EDIT` or `DM_ROLL_REQUEST`, it checks the sender against this list before accepting the command. This is a receiver-side security check — it does not expose any DM functionality.

### Removed from Player Addon

- `DM/DMPanel.lua`, `DM/DMComm.lua` — moved to NagaraDM.
- `NagaraDB.dmMode` flag — no longer needed; DM state lives in `NagaraDMDB`.
- `/nagara dm` slash command — replaced by NagaraDM's own commands.

## Consequences

- **Positive:** Privacy boundary is structural and impossible to accidentally violate.
- **Positive:** Single TOC and release zip for players — they never see DM code.
- **Positive:** The project is early (Phase 0), so no real DM code needs migration.
- **Negative:** Slight maintenance overhead — changes to the player namespace API (`NagaraNS`) can break the DM addon. Mitigated by explicit API documentation and running DM tests against current player code.
- **Negative:** Integration testing requires loading both addons' files together. The DIY test runner can handle this by including DM files in a separate test script.
