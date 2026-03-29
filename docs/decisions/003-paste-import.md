# ADR-003: Paste-Import for Character Data

**Status:** Accepted  
**Date:** 2026-03-29  
**Deciders:** Project owner + Copilot design session

## Context

Characters are created on the Nagara website. The addon needs a way to
receive new character data. Three approaches were evaluated:

| Approach                 | Mechanism                                                                         | Pros                       | Cons                                                       |
| ------------------------ | --------------------------------------------------------------------------------- | -------------------------- | ---------------------------------------------------------- |
| **A. Bot writes file**   | Discord bot places a `.lua` file in the addon folder; addon reads on login/reload | Automated                  | Requires bot infra, filesystem race risk, user must reload |
| **B. In-addon creation** | Users create characters directly in the addon                                     | No external deps           | Duplicates website work, complex UI                        |
| **C. Paste-import**      | Website shows export string; user pastes into addon EditBox                       | Simple, reliable, no infra | Manual copy-paste step                                     |

## Decision

**Approach C — paste-import** is the primary import path.

### Flow

1. User runs `/nagara import` → addon shows dialog with instructions and
   a URL the user can copy into their browser.
2. User opens the website, creates or selects a character.
3. Website: "Export for Addon" button strips irrelevant fields, serializes
   to a compact format, Base64-encodes, and displays a copyable string.
4. User pastes the string into the addon's EditBox.
5. Addon: Base64 decode → deserialize → validate → prompt confirm → store
   in `NagaraDB.characters[guid]`.

### EditBox Constraints

WoW's EditBox default `maxBytes` is 256 but can be raised via
`:SetMaxBytes(n)`. The practical paste limit is ~31 KB.
Charsheets are <4 KB encoded. No issues.

### Website API

The website provides an endpoint that produces an addon-optimized export:

- Strips fields the addon doesn't need (portrait, crop, backupCode, etc.).
- Returns data in a format that maps 1:1 to the addon's Lua table schema.
- See `docs/data-contracts.md` for the exact field list.

## Consequences

- **Positive:** Zero infrastructure beyond the existing website.
- **Positive:** Works immediately — no bot, no filesystem manipulation.
- **Positive:** User is in control of when data enters the addon.
- **Negative:** Requires a manual copy-paste step. Acceptable for a small
  group who will do this infrequently (new characters are rare events).
- **Future:** Approach A can be added later as a convenience upgrade
  without changing the core import logic.
