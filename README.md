# Nagara RPG

A World of Warcraft addon that helps roleplayers with a tabletop-style RPG system — character sheets, dice rolls, rules reference, abilities, spells, and more.

## Project Structure

```
Nagara/
├── Nagara.toc       -- Addon manifest (load order, metadata, SavedVariables)
├── Nagara.lua       -- Entry point: event frame, PLAYER_LOGIN, slash command
├── Core.lua         -- Core logic module placeholder
└── UI.lua           -- UI module placeholder
.github/
└── copilot-instructions.md  -- Copilot project guidance
```

## Installation

Create a directory symlink from your WoW AddOns folder to the `Nagara/` subfolder
in this repo (run as Administrator):

```powershell
New-Item -ItemType Junction `
    -Path "D:\Games\Aviana\AvianaRP\_retail_\Interface\AddOns\Nagara" `
    -Target "D:\proj\nagara\addon\Nagara"
```

Then restart the client or `/reload` in-game. Type `/nagara` to verify the addon
loaded.

## Development

- **Entry point**: `Nagara.lua` registers a hidden frame that listens for
  `PLAYER_LOGIN`. All other modules are loaded via the `.toc` file order.
- **SavedVariables**: `NagaraDB` persists across sessions. Initialised on first
  login in `Nagara.lua`.
- **Slash command**: `/nagara` is registered on load for quick testing.
