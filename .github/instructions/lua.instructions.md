---
applyTo: "Nagara/**/*.lua"
---

# Lua 5.1 — WoW Addon Conventions

## Language Constraints

- Target **Lua 5.1** only. The WoW client does not support 5.2+.
- Forbidden: `goto`, bitwise operators (`&`, `|`, `~`, `<<`, `>>`), `__gc` metamethod on tables, `\z` escape in strings, `load()` with mode arg.
- Use `loadstring()` not `load()` when dynamic code eval is required.
- `unpack` lives in global scope (not `table.unpack`).

## File Boilerplate

Every `.lua` file in `Nagara/` must start with:

```lua
local addonName, ns = ...
```

All file-level symbols are `local`. Export through `ns`:

```lua
local function doThing() ... end
ns.DoThing = doThing          -- PascalCase for namespace API
```

## Naming

| Scope           | Convention                  | Example                         |
| --------------- | --------------------------- | ------------------------------- |
| Constants       | `UPPER_SNAKE_CASE`          | `MAX_CHUNKS`, `PROTO_VERSION`   |
| Locals / params | `camelCase`                 | `chunkSize`, `targetName`       |
| Namespace API   | `PascalCase`                | `ns.DiceEngine`, `ns:OnLogin()` |
| Private helpers | `camelCase` local functions | `local parsePayload`            |

## Patterns

- Early-return over deep nesting:
  ```lua
  if not data then return end
  ```
- Avoid closures in tight loops — hoist functions.
- Never store mutable state in upvalues shared across event handlers
  without understanding the re-entrancy implications.
- Prefer `tinsert` / `tremove` / `wipe` (WoW globals) over manual table ops.

## WoW API Safety

- Never call secure-protected functions from insecure frames.
- Always check `InCombatLockdown()` before `Show()` / `Hide()` on frames that could be affected by taint.
- Register events on a dedicated hidden frame, not on UI frames.

## Performance Guardrails

- No `pairs()` / `ipairs()` in `OnUpdate` or per-frame handlers.
- Cache frequently accessed globals at file scope:
  ```lua
  local floor = math.floor
  local format = string.format
  ```
