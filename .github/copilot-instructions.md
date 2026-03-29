# Nagara RPG — Copilot Project Instructions

## About

- **Nagara** is a tabletop-style RPG system helper addon for World of Warcraft.
- It helps roleplayers store character sheets, roll dice, view rules/abilities/spells,
  and manage other RPG-related tasks in-game.

## Language & Runtime

- All addon code is **Lua 5.1** running inside the World of Warcraft client.
- The WoW API is available globally (e.g. `CreateFrame`, `C_Timer`, `hooksecurefunc`).
- Do **not** use Lua 5.2+ features (`goto`, bitwise operators, `__gc` on tables).

## Code Style

- Use `local` for all file-scoped variables and functions.
- Share state between files via the addon namespace: `local addonName, ns = ...`
- Prefer early-return over deep nesting.
- Name constants in `UPPER_SNAKE_CASE`, locals in `camelCase`, namespace methods in `PascalCase`.

## Project Conventions

- **Entry point**: `Nagara.lua` — event registration, slash commands, SavedVariables init.
- **Core.lua**: game-logic, data processing, no UI code.
- **UI.lua**: frame creation, layout, widget helpers.
- New modules: add a new `.lua` file, list it in `Nagara.toc` **after** its dependencies.

## SavedVariables

- The single persisted table is `NagaraDB`.
- Always guard with defaults on `PLAYER_LOGIN` so the addon never errors on first run.

## Things to Avoid

- Do **not** use `pairs`/`ipairs` in performance-critical per-frame code; pre-cache instead.
- Do **not** call secure-protected functions from insecure code in combat.
- Avoid global pollution — every top-level `local` should stay local.

## Testing

- Reload UI with `/reload` to pick up changes.
- Use `/nagara` slash command for quick manual smoke tests.

<!-- TODO: expand with feature-specific guidance as the project grows -->
