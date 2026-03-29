# ADR-006: Build-Time Static Database

**Status:** Accepted  
**Date:** 2026-03-29  
**Deciders:** Project owner + Copilot design session

## Context

Nagara's RPG rules data (~310 entries: 70 abilities, 50 spells,
30 rituals, 50 talents, 80 items, ~25 rule texts) is maintained
as JSON source files. The WoW Lua runtime has no native JSON parser.

## Decision

A build script (`scripts/build.py`) converts JSON source files into
Lua table literals at release time. The generated files are committed
to `Nagara/DB/` and shipped with the addon.

### Build-Time Conversion

```
temp/abilities.en.json  →  Nagara/DB/Abilities_en.lua
temp/abilities.ru.json  →  Nagara/DB/Abilities_ru.lua
temp/spells.en.json     →  Nagara/DB/Spells_en.lua
...
```

Each generated file registers its data on the namespace:

```lua
local _, ns = ...
ns.DB_Abilities_en = { ... }
```

`DB/Loader.lua` picks the active locale at runtime and assigns
`ns.DB.Abilities = ns.DB_Abilities_<lang>`.

### Source of Truth

Canonical data lives in JSON files under `temp/` (or a future `data/`).
The Lua files in `DB/` are **generated artifacts**. Manual edits to them
will be overwritten by the next build.

## Consequences

- **Positive:** No runtime JSON parsing. Instant load.
- **Positive:** Baked data can be loaded with standard Lua `dofile`
  semantics (TOC file list).
- **Positive:** ~310 entries is small enough for linear search — no
  indexing infrastructure needed.
- **Negative:** Two copies of the data (JSON + Lua). Accepted: the
  build script keeps them in sync automatically.
- **Negative:** Updating DB data requires a new addon release.
  Accepted: this data changes rarely and only the addon author
  controls releases.
