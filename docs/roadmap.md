# Nagara RPG — Implementation Roadmap

> Each milestone is self-contained and testable.
> Milestones roughly correspond to GitHub milestones / release tags.

## Phase 0 — Project Scaffolding ✱ START HERE

**Goal:** Build foundation so all future work has a place to land.

- [ ] Restructure repo: create folder tree (`Util/`, `Core/`, `DB/`, `Comm/`,
      `UI/`, `DM/`, `Import/`, `Locale/`, `test/`, `scripts/`).
- [ ] Update `Nagara.toc` with file load order (stubs for empty files).
- [ ] Create `Constants.lua` (version, color codes, enums).
- [ ] Create `test/wowstubs.lua` — minimal WoW API stubs.
- [ ] Set up `busted` locally; verify `busted test/` runs green with a
      trivial smoke test.
- [ ] GitHub Actions CI: `.github/workflows/test.yml` runs `busted` on push.
- [ ] `scripts/build.py` skeleton: reads JSON, emits Lua, bumps TOC, creates zip.
- [ ] GitHub Actions release workflow: on `v*` tag → run tests → build → upload zip.

**Deliverable:** Green CI, working build script, empty but loadable addon.

---

## Phase 1 — Util/ & Core Data Model (no UI)

**Goal:** Implement and fully test the foundational utilities and data model.

### 1a — Utilities

- [ ] `Util/Serialize.lua` — table ↔ string. Tests: round-trip for all types,
      edge cases (empty tables, nils, special characters, nested tables).
- [ ] `Util/Base64.lua` — encode / decode. Tests: round-trip, binary-safe,
      zero-length input, padding.
- [ ] `Util/Callbacks.lua` — pub/sub mixin. Tests: register, fire, unregister,
      multiple listeners, fire with no listeners.

### 1b — Character Data Model

- [ ] `Core/CharSheet.lua` — canonical schema, `SCHEMA_VERSION`, defaults,
      field validation, migration stubs.
- [ ] Tests: create with defaults, validate valid/invalid data, migrate v1→v2.

### 1c — Effects Pipeline

- [ ] `Core/Effects.lua` — modifier resolution: `setBase → addFlat → multiply → cap`.
- [ ] Tests: known-input/known-output for each modifier type, priority ordering,
      stacking, empty effects list.

**Deliverable:** All Util + Core logic tested in CI. No in-game dependency yet.

---

## Phase 2 — Static Database & Build Pipeline

**Goal:** Bake rules data into the addon and make it queryable.

- [ ] `scripts/build.py` JSON→Lua conversion for: abilities, spells, rituals,
      talents, items, rules text. Two locales (ru, en).
- [ ] `DB/Loader.lua` — locale selection, expose via `ns.DB.Abilities` etc.
- [ ] `Core/Search.lua` — name + tag matching. Tests: exact match, partial,
      tag filter, no results.
- [ ] `Locale/enUS.lua`, `Locale/ruRU.lua` — initial UI string tables.
- [ ] Verify generated Lua files load cleanly in `busted` tests.

**Deliverable:** Full static DB baked and searchable. Build script produces
a release-ready zip.

---

## Phase 3 — Basic UI: Own Charsheet (Read-Only)

**Goal:** See your own character data in-game. First visual milestone.

- [ ] `UI/Widgets.lua` — reusable widget factories (label, button, scrollframe, tabs).
- [ ] `UI/MainFrame.lua` — top-level window, draggable, closable, ESC-to-close,
      combat-hide on `PLAYER_REGEN_DISABLED` / re-show on `ENABLED`.
- [ ] `UI/CharSheetPanel.lua` — tabbed layout (attributes, equipment, background, effects).
      Read-only for now.
- [ ] `/nagara` slash command toggles the main frame.
- [ ] Minimap button (optional, low priority).

**Deliverable:** `/nagara` opens a window showing your character sheet.

---

## Phase 4 — Import & Own Charsheet Editing

**Goal:** Get character data into the addon; allow local edits.

### 4a — Paste-Import

- [ ] `UI/ImportDialog.lua` — EditBox with instructions, decode status.
- [ ] `Import/PasteImport.lua` — Base64 decode → deserialize → validate → store.
- [ ] Tests: valid input, truncated input, wrong schema version, garbage data.
- [ ] `/nagara import` opens the import dialog.

### 4b — Local Editing

- [ ] Charsheet inline editors for mutable fields (toughness current,
      experience, corruption, equipment, journal notes).
- [ ] Save edits to `NagaraDB.characters[guid]`.
- [ ] Profile switching: `/nagara profile <name>`, `NagaraDB.activeProfile`.

**Deliverable:** Full local character management loop.

---

## Phase 5 — Dice Rolling

**Goal:** Core gameplay feature — roll dice from the UI.

- [ ] `Core/DiceEngine.lua` — parse formula (`2d6+3`, `d20`, attribute check),
      apply modifiers from Effects pipeline, roll, return structured result.
- [ ] Tests: formula parsing, roll range validation, modifier application.
- [ ] `UI/DicePanel.lua` — buttons for common rolls, custom formula input,
      result display, roll history (last N rolls).
- [ ] `UI/CompactBar.lua` — dice-only minimal bar (compact mode).
- [ ] Mode toggle: full ↔ compact via button or `/nagara compact`.

**Deliverable:** Users can roll dice with buttons. Two UI modes work.

---

## Phase 6 — Rules & Ability Browser

**Goal:** Look up, read, and search RPG data in-game.

- [ ] `UI/BrowserPanel.lua` — search box, results scroll list, detail view.
- [ ] Tab in MainFrame for the browser.
- [ ] Detail view: ability tiers (novice/adept/master), spell descriptions,
      item descriptions, rule text.
- [ ] Wire up `Core/Search.lua` to the UI.

**Deliverable:** Users can search and read rules/abilities/spells in-game.

---

## Phase 7 — Chat Links

**Goal:** Share discovered information with other Nagara users.

- [ ] `UI/LinkHandler.lua` — create `|Hnagara:type:id|h[Display Name]|h` links.
- [ ] Hook `SetItemRef` to intercept clicks → open BrowserPanel to the linked entry.
- [ ] "Share" button in BrowserPanel detail view → inserts link into chat editbox.
- [ ] Tests: link encode/decode round-trip, malformed link handling.

**Deliverable:** Click a link in chat → addon opens the relevant page.

---

## Phase 8 — Communication & Profile Sync

**Goal:** View other players' character sheets.

### 8a — Protocol Foundation

- [ ] `Comm/Protocol.lua` — message type enum, envelope encode/decode.
- [ ] `Util/Chunker.lua` — split/reassemble at 251-byte boundary.
- [ ] `Util/Throttle.lua` — send queue with `C_Timer.After` drip.
- [ ] Tests: encode/decode round-trips, chunker split/reassemble,
      throttle queue ordering.

### 8b — Profile Sync

- [ ] `Comm/Sync.lua` — `RequestProfile(target)`, `HandleProfileRequest()`,
      `HandleProfileResponse()`, cache management.
- [ ] Trigger: click target's character model → request profile.
- [ ] Display cached profile in CharSheetPanel (read-only).
- [ ] Cache staleness: compare `lastModified` timestamps.
- [ ] Cache pruning: remove entries older than N days on login.

**Deliverable:** Click another Nagara user → see their charsheet.

---

## Phase 9 — DM Mode

**Goal:** DM-specific features.

- [ ] `DM/DMPanel.lua` — edit fields on other characters' sheets.
- [ ] `DM/DMComm.lua` — `DM_EDIT` message type, receiver-side
      allow-list validation, `DM_EDIT_ACK` response.
- [ ] DM roll requests: DM sends `DM_ROLL_REQUEST` → player sees
      prompt → rolls → result auto-sent back to DM.
- [ ] `/nagara dm` toggles DM mode (guarded by `DM_NAMES` check).

**Deliverable:** DM can edit others' sheets and request rolls.

---

## Phase 10 — Polish & Packaging

**Goal:** Release-ready quality.

- [ ] Cache pruning and SavedVariables size monitoring.
- [ ] Error handling: graceful degradation on malformed data, version
      mismatch warnings, "please update" prompts.
- [ ] Locale completeness pass (ruRU + enUS).
- [ ] In-game `/nagara test` smoke test suite.
- [ ] README with install instructions, screenshot, feature overview.
- [ ] Final CI pipeline validation. Tag `v1.0.0`.

**Deliverable:** First full release.

---

## Future (Post-1.0)

- Discord bot → SavedVariables auto-import (ADR-003 Approach A).
- Character creation directly in-addon.
- Roll macros / saved roll presets.
- Visual combat tracker (DM tool).
- Profile versioning and diff-based sync (send only changed fields).
