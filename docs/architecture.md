# Nagara RPG — System Architecture

> Living document. Updated as the design evolves.

## 1. Overview

Nagara is a World of Warcraft addon that provides a tabletop RPG system layer on top of the game client. It is used by a small, closed group of roleplayers and is distributed exclusively via GitHub Releases.

```
┌──────────────────────────────────────────────────────────────┐
│                     WoW Client Process                       │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Nagara Addon  (Lua 5.1, no external libs)              │ │
│  │                                                         │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐               │ │
│  │  │  Util/   │  │  Core/   │  │   DB/    │               │ │
│  │  │ Serialize│  │ CharSheet│  │ Abilities│               │ │
│  │  │ Base64   │  │ Dice     │  │ Spells   │               │ │
│  │  │ Callbacks│  │ Effects  │  │ Items    │               │ │
│  │  │ Chunker  │  │ Rules    │  │ Loader   │               │ │
│  │  │ Throttle │  │ Search   │  │ ...      │               │ │
│  │  └──────────┘  └──────────┘  └──────────┘               │ │
│  │        │              │             │                   │ │
│  │  ┌─────┴──────────────┴─────────────┴──────────┐        │ │
│  │  │              Namespace (ns)                 │        │ │
│  │  └──────┬──────────────┬──────────────┬────────┘        │ │
│  │         │              │              │                 │ │
│  │  ┌──────┴───┐   ┌──────┴───┐                    │ │
│  │  │  Comm/   │   │   UI/    │                    │ │
│  │  │ Protocol │   │ MainFrame│                    │ │
│  │  │ Sync     │   │ Charsheet│                    │ │
│  │  │          │   │ Compact  │                    │ │
│  │  │          │   │ Dice     │                    │ │
│  │  │          │   │ Browser  │                    │ │
│  │  │          │   │ Import   │                    │ │
│  │  │          │   │ Links    │                    │ │
│  │  └──────────┘   └──────────┘                    │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────┐               │ │
│  │  │  NagaraDB   (SavedVariables)         │               │ │
│  │  │  .characters  .cache  .settings      │               │ │
│  │  │  .activeProfile                       │               │ │
│  │  └──────────────────────────────────────┘               │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  WoW APIs: C_ChatInfo · C_Timer · CreateFrame · ...          │
└──────────────────────────────────────────────────────────────┘

         ▲ paste-import string         paste-export string ▼
         │                              (player fallback)  │
┌────────┴─────────────────────────────────────────────────┴──┐
│                      Nagara Website                         │
│                    (character builder)                      │
└────────▲────────────────────────────────────────────────────┘
         │
         │  sync_upload.py  (DM only, offline)
         │  reads WTF/.../NagaraDB.lua
         │  POSTs changed profiles
```

## 2. Layer Responsibilities

### 2.1 Util/ — Pure Helpers

Zero WoW-API dependencies in hot paths. Fully testable outside the client.

| Module          | Purpose                                                 |
| --------------- | ------------------------------------------------------- |
| `Callbacks.lua` | Publish / subscribe event mixin (~40 LOC)               |
| `Serialize.lua` | Lua table ↔ string. Used by Comm and paste-import       |
| `Base64.lua`    | Encode / decode for paste-import strings                |
| `Chunker.lua`   | Split / reassemble messages at the 255-byte boundary    |
| `Throttle.lua`  | FIFO send queue with `C_Timer.After` drip (~4 KB/s cap) |

### 2.2 Core/ — Game Logic

No UI code. No direct frame manipulation.

| Module           | Purpose                                                                      |
| ---------------- | ---------------------------------------------------------------------------- |
| `CharSheet.lua`  | Canonical data model, defaults, field validation, schema migrations          |
| `DiceEngine.lua` | Roll formulas, modifier application, result formatting                       |
| `Effects.lua`    | Modifier pipeline: `setBase → addFlat → multiply → cap`                      |
| `Rules.lua`      | Rule look-ups, derived-stat calculation (defense, thresholds)                |
| `Search.lua`     | Name / tag matching across DB entries (linear scan is fine for ~310 entries) |

### 2.3 DB/ — Static Data

Lua table literals generated at **build time** from canonical JSON source files. Never mutated at runtime.

- One file per category × locale (e.g., `Abilities_ru.lua`, `Abilities_en.lua`) or a single file with both locales keyed by language code.
- `Loader.lua` selects the active locale at startup via `GetLocale()`.

### 2.4 Locale/

Flat `L["key"] = "value"` tables for UI strings.
`enUS.lua` is the fallback; `ruRU.lua` is the primary locale.

### 2.5 Comm/ — Networking

| Module         | Purpose                                               |
| -------------- | ----------------------------------------------------- |
| `Protocol.lua` | Message types enum, envelope format, encode / decode  |
| `Sync.lua`     | Profile request/response flow, cache freshness checks |

Wire format: `[protoVersion:1B][msgType:1B][seqNum:1B][totalChunks:1B][payload]`
Transport: `C_ChatInfo.SendAddonMessage("Nagara", …, "WHISPER", target)`

### 2.6 UI/

All frames are fully insecure (no spell casting, no targeting).
On `PLAYER_REGEN_DISABLED` → instantly hide everything.
On `PLAYER_REGEN_ENABLED` → allow re-opening.

| Module               | Purpose                                                          |
| -------------------- | ---------------------------------------------------------------- |
| `MainFrame.lua`      | Top-level window, mode toggle (full / compact), keybind          |
| `CharSheetPanel.lua` | Tabbed character sheet display                                   |
| `CompactBar.lua`     | Dice-only minimal bar                                            |
| `DicePanel.lua`      | Roll buttons, result display, history                            |
| `BrowserPanel.lua`   | Rules / ability / spell search + detail view                     |
| `ImportDialog.lua`   | Paste-import EditBox with decode + validation                    |
| `Widgets.lua`        | Reusable widget factories (buttons, scroll lists, tabs)          |
| `LinkHandler.lua`    | `\|Hnagara:…\|h` creation + `SetItemRef` hook for click handling |

### 2.7 Import/

| Module            | Purpose                                                        |
| ----------------- | -------------------------------------------------------------- |
| `PasteImport.lua` | Decode Base64 → deserialize → validate schema → prompt → store |

> **Note:** DM features (DMPanel, DMComm) live in the separate **NagaraDM** addon,
> which depends on Nagara via `## Dependencies: Nagara` in its TOC.
> See ADR-009 for details.

## 3. Data Flow Diagrams

### 3.1 Paste-Import

```
User                    Website                 Addon
 │  opens URL ────────►  │                       │
 │                       │  build character      │
 │  ◄──── export string  │                       │
 │                       │                       │
 │  /nagara import ──────────────────────────────► ImportDialog
 │  paste string ────────────────────────────────► PasteImport
 │                                               │ Base64 decode
 │                                               │ Deserialize
 │                                               │ Validate schema
 │                                               │ Prompt confirm
 │                                               ▼
 │                                          NagaraDB.characters[guid]
```

### 3.2 Profile Sync

```
Player A                              Player B
 │                                      │
 │  click B's model                     │
 │  ──► Sync:RequestProfile(B) ────────►│
 │      { versionHash }                 │
 │                                      │ compare hash vs own lastModified
 │                                      │
 │  ◄── PROFILE_RESPONSE "up-to-date"   │  (hashes match)
 │      or                              │
 │  ◄── PROFILE_CHUNK 1/N … N/N ──────│  (stale → send full)
 │                                      │
 │  reassemble → cache[B]               │
 │  CharSheetPanel(readOnly)            │
```

### 3.3 DM Edit (Player-Side Handling)

DM edit and roll-request messages are sent by the **NagaraDM** addon.
The player addon only handles the **receiving** side:

```
NagaraDM (DM's client)                Player
 │  DM_EDIT { target, field, val } ───►│
 │                                     │ check DM_NAMES allow-list
 │                                     │ apply edit
 │                                     │ ack
 │  ◄── DM_EDIT_ACK ─────────────────│
```

### 3.4 Addon → Website (ADR-008)

```
  ┌── Primary path (DM only, post-session) ──────────────────────┐
  │                                                              │
  │  WTF/.../NagaraDB.lua                                        │
  │       │                                                      │
  │       ▼                                                      │
  │  scripts/sync_upload.py                                      │
  │       │  parse NagaraDB.cache                                │
  │       │  compare lastModified                                │
  │       │  POST changed profiles                               │
  │       ▼                                                      │
  │  Website API                                                 │
  └──────────────────────────────────────────────────────────────┘

  ┌── Fallback path (any player, in-game) ───────────────────────┐
  │                                                              │
  │  NagaraDB.characters[guid]                                   │
  │       │                                                      │
  │       ▼                                                      │
  │  Serialize → Base64 encode → display in EditBox              │
  │       │                                                      │
  │       │  user copies string                                  │
  │       ▼                                                      │
  │  Paste into website import form                              │
  └──────────────────────────────────────────────────────────────┘
```

### 3.5 Dice Roll

```
User clicks roll button
 │
 ▼
DiceEngine:Roll(formula, attribute, modifiers)
 │  ├─ apply Effects pipeline for active character
 │  ├─ math.random(1, sides) per die
 │  ├─ sum + modifiers
 │  └─ return { rolls, total, success/fail }
 │
 ▼
Display result locally (DicePanel)
 │
 ▼
Broadcast via Comm (ROLL_RESULT → party/whisper)
```

## 4. SavedVariables Schema (NagaraDB)

```lua
NagaraDB = {
    schemaVersion = 1,              -- DB-level migration version
    settings = {
        locale = "ruRU",            -- override, or nil = auto-detect
        compactMode = false,
        minimap = { show = true },
    },
    activeProfile = "charGuid",     -- GUID of the currently active profile
    characters = {
        ["<guid>"] = {              -- one entry per imported profile
            schemaVersion = 1,      -- per-character migration version
            characterName = "…",
            lastModified = "…",
            -- ... (see docs/data-contracts.md)
        },
    },
    cache = {
        ["Playername-Realm"] = {    -- cached profiles from other players
            data = { … },
            cachedAt = 1711700000,  -- time() timestamp
        },
    },
}
```

## 5. Build & Scripts Pipeline

```
temp/*.json  ──►  scripts/build.py  ──►  Nagara/DB/*.lua   (baked Lua tables)
                       │
                       ├──►  bump Nagara.toc version
                       └──►  zip Nagara/ → dist/Nagara-vX.Y.Z.zip

Post-session sync (DM only, see ADR-008):
  WTF/.../NagaraDB.lua  ──►  scripts/sync_upload.py  ──►  Website API
                                    │
                                    └──►  compares lastModified
                                    └──►  POSTs changed characters

GitHub Actions (on tag push v*):
  1. checkout
  2. lua 5.1 → lua test/run.lua   (DIY runner)
  3. python scripts/build.py
  4. upload zip as GitHub Release asset
```

## 6. Testing Strategy

| Layer                                                      | Method            | Runner                       |
| ---------------------------------------------------------- | ----------------- | ---------------------------- |
| Util/, Core/, DB/Loader, Comm/Protocol, Import/PasteImport | Unit tests        | `lua test/run.lua` (DIY, CI) |
| UI smoke, combat-hide, link clicks                         | `/nagara test`    | In-game                      |
| Comm round-trip, sync                                      | Dual-box / friend | Manual                       |

Test runner is hand-written (~125 LOC). See ADR-007.
Test files mirror source: `test/test_serialize.lua` tests `Util/Serialize.lua`.

Project structure for tests:

```
test/                           -- NOT shipped; lives at repo root
├── run.lua                     -- DIY test runner
├── wowstubs.lua                -- Minimal WoW API stubs
├── test_serialize.lua
├── test_base64.lua
├── test_charsheet.lua
├── test_dice.lua
├── test_effects.lua
├── test_search.lua
├── test_chunker.lua
└── test_protocol.lua
```

A minimal `test/wowstubs.lua` stubs `CreateFrame`, `C_Timer`, `GetTime`,
`strtrim`, `GetLocale`, etc.

## 7. Key Constraints

- **Zero external dependencies.** See ADR-001.
- **No MSP.** See ADR-002.
- **No runtime JSON parsing.** All data baked at build time.
- **Hide on combat.** `PLAYER_REGEN_DISABLED` → hide all frames instantly.
- **Charsheet payloads < 4 KB.** No compression needed at this scale.
- **~310 DB entries.** Linear search is fine; no indexing needed.
