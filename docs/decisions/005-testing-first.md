# ADR-005: Testing-First with Busted + WoW Stubs

**Status:** Accepted  
**Date:** 2026-03-29  
**Deciders:** Project owner + Copilot design session

## Context

WoW addons have no built-in testing framework. Debugging in-game is slow
(edit → `/reload` → observe). Catching regressions requires either
manual testing or an external test harness.

## Decision

- **Testing-first policy:** write tests before implementation where practical.
- Pure-logic modules (`Util/`, `Core/`, `DB/Loader`, `Comm/Protocol`,
  `Import/PasteImport`) are tested **outside WoW** with Lua 5.1 + `busted`.
- A minimal `test/wowstubs.lua` provides stubs for the WoW API surface
  that addon code touches (`CreateFrame`, `C_Timer`, `GetLocale`,
  `strtrim`, `GetTime`, etc.).
- CI runs `busted test/` on every push via GitHub Actions.

### In-Game Tests

- `/nagara test` runs a suite of smoke tests that exercise subsystems
  with canned data and report pass/fail to chat.
- Tests cover: UI frame creation, combat-hide behavior, link click
  handling, actual `SendAddonMessage` round-trip (with a second character).

### Test Coverage Targets

| Area                            | Coverage goal                            |
| ------------------------------- | ---------------------------------------- |
| Serialize round-trip            | High — this is the most critical utility |
| Base64 encode/decode            | High                                     |
| Charsheet validation & defaults | High                                     |
| Dice formulas                   | High                                     |
| Effect pipeline ordering        | High                                     |
| Schema migration                | High                                     |
| Search matching                 | Medium                                   |
| Protocol encode/decode          | High                                     |
| UI rendering                    | Smoke only (in-game)                     |
| Live comm                       | Manual integration                       |

## Consequences

- **Positive:** Fast feedback loop for logic changes.
- **Positive:** CI catches regressions without WoW access.
- **Negative:** Must maintain WoW API stubs — they can drift
  from the real API. Mitigated by keeping stubs minimal and
  only stubbing what we actually call.
