# ADR-008: Website Sync via DM Cache + Script

**Status:** Accepted  
**Date:** 2026-03-31  
**Deciders:** Project owner + Copilot design session

## Context

Character data flows **into** the addon via paste-import (ADR-003). The website also acts as the canonical long-term store for character data. When the DM or players edit character fields in-game (experience, corruption, toughness, equipment, journal, etc.), those changes need to propagate **back** to the website so it stays up-to-date.

Two approaches were evaluated:

**A. DM cache + standalone script (local)**

- The DM's addon caches every player's profile via the comm protocol.
- After a session, a locally-run script reads the DM's SavedVariables file, extracts cached character data, and makes API calls to the website to update changed characters.

**B. Reverse paste-export (per-player fallback)**

- The addon generates an export string for the active profile.
- The player copies it and pastes it into a website "Update from Addon" page.
- No infrastructure needed, but shifts the burden to every player.

## Decision

**Approach A — DM cache + standalone script** is the primary sync path.
**Approach B — reverse paste-export** is a per-player fallback.

### Primary Path: DM Script

```
WoW session ends
  └─► NagaraDB.lua written to disk (WoW SavedVariables)
         │
  scripts/sync_upload.py (or .lua)
         │ reads NagaraDB.cache from WTF/.../NagaraDB.lua
         │ also reads NagaraDB.characters (DM's own profiles)
         │
         │ for each character:
         │   compare lastModified vs website's stored version
         │   skip if unchanged
         │   POST /api/characters/:id/sync   (changed ones only)
         │
         └─► website database updated
```

The script:

- Lives in `scripts/` alongside `build.py`. Part of the repo but **not** included in the addon release zip.
- Reads a Lua SavedVariables file and parses the relevant tables. (Python option: use `slpp` or a small custom parser. Lua option: `dofile` the SavedVariables and emit JSON.)
- Authenticates to the website API with a DM-only token (stored in a local config file, never committed).
- Is run manually by the DM after sessions (or automated via a local cron/task scheduler if desired).

### Fallback: Reverse Paste-Export

- `/nagara export` (or an "Export" UI button) serializes the active profile, Base64-encodes it, and displays it in a copyable EditBox.
- Any player can copy the string and paste it into the website.
- Uses the same `Serialize.lua` + `Base64.lua` already built for import.
- Useful when: a player makes changes outside of a DM session, or the DM hasn't run the sync script yet.

### Website API Requirements

The website needs one additional endpoint:

```
POST /api/characters/:id/sync
Headers: Authorization: Bearer <dm-token>
Body: { character data matching the addon schema }
Response: 200 OK | 409 Conflict (if website version is newer)
```

On conflict, the script should warn and skip rather than overwrite.

## Consequences

- **Positive:** Single point of upload (DM), no per-player setup.
- **Positive:** Leverages data already being cached by the addon's comm layer — no new addon feature needed for the primary path.
- **Positive:** Script shares tooling and conventions with `build.py`.
- **Positive:** Fallback export costs almost nothing to implement (reuses existing serializer + base64).
- **Negative:** DM must remember to run the script after sessions. Acceptable — it's one person with a routine.
- **Negative:** Slight delay between session end and website update. Not a problem for this use case.
