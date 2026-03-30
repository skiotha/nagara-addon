# Nagara RPG

A World of Warcraft addon that provides a tabletop-style RPG system layer for a group of roleplayers: character sheets, dice rolls, rules reference, abilities, spells, and more.

- **Not** distributed via CurseForge / WoWInterface. Released as [GitHub Release](https://github.com/skiotha/nagara-addon/releases) zips.
- Two modes in one addon: **Player** and **DM** (toggled via `NagaraDB.dmMode`).
- **Zero external dependencies** — no Ace3, LibStub, or any third-party library.
- Characters are imported via **paste-import** (Base64 string from the companion website).
- Primary locale: **ruRU**. Secondary: **enUS**.

## Project Structure

```
Nagara/                         -- addon folder (ships to Interface/AddOns/)
├── Nagara.toc                  -- Addon manifest (load order, SavedVariables)
├── Nagara.lua                  -- Entry point: events, slash commands, DB init
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
docs/                           -- design docs (not shipped)
├── architecture.md
├── data-contracts.md
├── roadmap.md
└── decisions/                  -- ADRs
temp/                           -- scratch / sample data (not shipped)
test/                           -- busted tests (not shipped)
scripts/                        -- build & release tooling (not shipped)
```

> The addon is currently **early in development** (Phase 0 — scaffolding).
> Many of the files above don't exist yet. See
> [docs/roadmap.md](docs/roadmap.md) for the implementation plan.

## Installation

1. Download the latest zip from
   [Releases](https://github.com/skiotha/nagara-addon/releases).
2. Extract the `Nagara/` folder into your WoW AddOns directory (e.g. `World of Warcraft\_retail_\Interface\AddOns\`).
3. Restart the client or `/reload` in-game.
4. Type `/nagara` to verify the addon loaded.

## Usage

- `/nagara` — toggle the main window.
- `/nagara import` — open the paste-import dialog.
- `/nagara profile <name>` — switch active character profile.
- `/nagara compact` — toggle compact (dice-only) mode.
- `/nagara dm` — toggle DM mode (authorized users only).

## Development

> This section is for contributors and developers working on the addon source.

### Setup

Clone the repo and create a directory junction so WoW loads the addon directly from your working copy (run as Administrator):

```powershell
New-Item -ItemType Junction `
    -Path "D:\Games\WoW\_retail_\Interface\AddOns\Nagara" `
    -Target "<your-clone-path>\Nagara"
```

### Architecture

- **Language**: Lua 5.1 (WoW client runtime). No 5.2+ features.
- **Entry point**: `Nagara.lua` registers a hidden frame that listens for `PLAYER_LOGIN`. All other modules are loaded via the `.toc` file order.
- **Namespace**: files share state via `local addonName, ns = ...`
- **SavedVariables**: `NagaraDB` persists across sessions. Initialised with defaults on first login in `Nagara.lua`.
- **Code style**: `UPPER_SNAKE_CASE` constants, `camelCase` locals, `PascalCase` namespace methods. Lines ≤ 120 chars. Early-return over nesting.

### Testing

- Pure logic (`Util/`, `Core/`, `DB/`, `Comm/Protocol.lua`) is tested outside WoW with **Lua 5.1 + [busted](https://olivinelabs.com/busted/)** against a minimal WoW API stub (`test/wowstubs.lua`).
- CI runs `busted test/` on every push via GitHub Actions.
- In-game smoke tests via `/nagara test` for UI and live comm.

### Build & Release

- `scripts/build.py` converts JSON → Lua DB files, bumps the TOC version, and creates a release zip.
- GitHub Actions on tag push (`v*`) runs tests then creates a GitHub Release with the zip.

## Documentation

| Document                                    | Description                                                     |
| ------------------------------------------- | --------------------------------------------------------------- |
| [architecture.md](docs/architecture.md)     | System architecture, layer responsibilities, data flow diagrams |
| [data-contracts.md](docs/data-contracts.md) | Character schema, SavedVariables format, comm wire protocol     |
| [roadmap.md](docs/roadmap.md)               | Phased implementation plan (Phase 0–10)                         |
| [decisions/](docs/decisions/)               | Architecture Decision Records (ADRs)                            |
