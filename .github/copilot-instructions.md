# Nagara RPG — Copilot Project Instructions

> Authoritative rules for every Copilot session working on this project.
> For detailed architecture, road-map, and ADRs see `docs/`.

## About

- **Nagara** is a tabletop-style RPG helper addon for World of Warcraft.
- It stores character sheets, rolls dice, looks up rules/abilities/spells, and manages RPG-related tasks in-game for a small group of like-minded roleplayers (a guild or community, probably).
- **Not** distributed via CurseForge / WoWInterface. Released as GitHub Release zips.
- Two logical modes in one addon: **Player** and **DM** (toggled via `NagaraDB.dmMode`).

## Language & Runtime

- All addon code is **Lua 5.1** running inside the World of Warcraft client.
- The WoW API is available globally (`CreateFrame`, `C_Timer`, `C_ChatInfo`, `hooksecurefunc`, etc.).
- Do **not** use Lua 5.2+ features (`goto`, bitwise operators, `__gc` on tables, `\z` escapes).

## Zero-Dependency Policy

- The addon has **no external library dependencies** (no Ace3, LibStub, LibCompress, LibMSP, etc.).
- All utilities (serializer, base64, callbacks, message chunker, send throttle) are hand-written in `Util/` and kept minimal.
- Rationale: closed user-base, small payloads (<4 KB charsheets), full control, no version-mismatch issues.

## Code Style

- Use `local` for all file-scoped variables and functions.
- Share state between files via the addon namespace: `local addonName, ns = ...`
- Prefer early-return over deep nesting.
- Constants: `UPPER_SNAKE_CASE`. Locals: `camelCase`. Namespace methods: `PascalCase`.
- Keep lines ≤ 120 characters where practical.

## Project Layout

```
Nagara/                         -- the addon folder (ships to Interface/AddOns/)
├── Nagara.toc
├── Nagara.lua                  -- Entry: events, slash commands, SavedVariables init
├── Constants.lua               -- Version, colours, enums, limits, DM name list
├── Util/                       -- Pure-Lua helpers (no WoW API in hot paths)
│   ├── Callbacks.lua
│   ├── Serialize.lua
│   ├── Base64.lua
│   ├── Chunker.lua
│   └── Throttle.lua
├── Core/                       -- Game logic (no UI code)
│   ├── CharSheet.lua
│   ├── DiceEngine.lua
│   ├── Effects.lua
│   ├── Rules.lua
│   └── Search.lua
├── DB/                         -- Static data (build-time generated from JSON)
│   ├── Abilities.lua
│   ├── Spells.lua
│   ├── Rituals.lua
│   ├── Talents.lua
│   ├── Items.lua
│   ├── RulesText.lua
│   └── Loader.lua
├── Locale/
│   ├── enUS.lua
│   └── ruRU.lua
├── Comm/
│   ├── Protocol.lua
│   └── Sync.lua
├── UI/
│   ├── MainFrame.lua
│   ├── CharSheetPanel.lua
│   ├── CompactBar.lua
│   ├── DicePanel.lua
│   ├── BrowserPanel.lua
│   ├── ImportDialog.lua
│   ├── Widgets.lua
│   └── LinkHandler.lua
├── DM/
│   ├── DMPanel.lua
│   └── DMComm.lua
└── Import/
    └── PasteImport.lua
```

- New modules: create a `.lua` file in the appropriate subfolder, list it in `Nagara.toc` **after** its dependencies.
- `temp/` and `test/` are **never** shipped; they live at repo root.

## SavedVariables

- The single persisted table is `NagaraDB`.
- Always guard with defaults on `PLAYER_LOGIN` so the addon never errors on first run.
- Key sub-tables: `NagaraDB.characters`, `NagaraDB.cache`, `NagaraDB.settings`, `NagaraDB.dmMode`, `NagaraDB.dmNames`, `NagaraDB.activeProfile`.
- Each stored character carries a `schemaVersion` number for forward migration.

## Communication Protocol

- **Custom protocol** over `C_ChatInfo.SendAddonMessage` with prefix `"Nagara"`.
- **No MSP.** The user-base is closed; MSP interop is unnecessary.
- Message envelope: `[protoVersion:1B][msgType:1B][seqNum:1B][totalChunks:1B][payload]`.
- Payloads serialized with `Util/Serialize.lua`, chunked at 251 usable bytes per message.
- A simple timer-based send queue (`Util/Throttle.lua`) respects WoW's ~4 KB/s outgoing cap.

## Character Data Model

- Characters are imported via **paste-import** (Base64-encoded string from the website).
- Nagara profiles can map to WoW character N:1. Players swap via `/nagara profile <name>`.
- One "active profile" is transmitted when another player requests inspection.
- DM authorization: receiver checks sender against `DM_NAMES` list in `Constants.lua`.

## Static Database

- ~310 entries total: 70 abilities, 50 spells, 30 rituals, 50 talents, 80 items, ~25 rule texts.
- Stored as Lua table literals in `DB/`, either **generated at build time** from source JSON.
- Changes only on new addon releases — never at runtime.
- Short enough for linear search (no indexing infrastructure needed).

## Localization

- Primary locale: **ruRU**. Secondary: **enUS**.
- UI strings live in `Locale/{enUS,ruRU}.lua` as flat `L["key"] = "value"` tables.
- DB data is locale-split per file (`Abilities.lua` contains current locale, chosen at build or runtime via `DB/Loader.lua`).

## Taint & Combat Rules (CRITICAL)

- **Never** touch Blizzard secure frames or `Blizzard_*` globals from addon code.
- All Nagara frames are **insecure** (they never cast spells or target).
- On `PLAYER_REGEN_DISABLED` (entering combat): **immediately hide** all Nagara frames.
- On `PLAYER_REGEN_ENABLED` (leaving combat): allow re-opening.
- Guard any `Show()`/`Hide()` with `InCombatLockdown()` checks if the frame
  could theoretically be parented to a secure frame.

## Testing

- **Testing-first policy.** Write tests before implementation where possible.
- **DIY test runner** (`test/run.lua`, ~125 LOC) — no external test framework (no busted, no luarocks).
  Provides `describe` / `it` / `expect` interface. See ADR-007.
- Pure logic (`Util/`, `Core/`, `DB/`, `Comm/Protocol.lua`) is tested outside WoW with Lua 5.1 + `test/run.lua` against a minimal WoW API stub (`test/wowstubs.lua`).
- CI runs `lua test/run.lua` on every push via GitHub Actions.
- In-game smoke tests via `/nagara test` for UI and live comm.
- Manual integration testing with a second character / friend.

## Build & Release

- `scripts/build.py`: converts JSON → Lua DB files, bumps TOC version, zips `Nagara/`.
- `scripts/sync_upload.py`: DM-only post-session tool — reads `NagaraDB.lua`,
  syncs changed character data to the website API. See ADR-008.
- Scripts live at repo root in `scripts/`, **never** shipped in the addon zip.
- GitHub Actions on tag push (`v*`) runs tests then creates a GitHub Release with the zip.
- Users download the zip and extract into `Interface/AddOns/`.

## Things to Avoid

- **No global pollution** — every top-level `local` stays local.
- **No `pairs`/`ipairs` in per-frame code** — pre-cache instead.
- **No secure-function calls from insecure code** during combat.
- **No runtime JSON parsing** — all data converted at build time.
- **No external library dependencies** (see Zero-Dependency Policy above).
- **No unnecessary features** — do not add code beyond what is directly planned.
