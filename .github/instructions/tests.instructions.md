---
applyTo: "test/**"
---

# Test Conventions

## Framework

- Tests run outside WoW with **Lua 5.1** and a **hand-written test runner** (`test/run.lua`).
- No external test framework (no busted, no luarocks). See ADR-007.
- The runner provides `describe`, `it`, `expect`, `beforeEach`, `afterEach`.
- WoW API stubs live in `test/wowstubs.lua` — loaded before any addon file.
- Tests should never require the actual WoW client or network.
- Run all tests: `lua test/run.lua`
- Exit code 0 = all passed, 1 = failures.

## File Naming

- One test file per module: `test/test_<module>.lua`
  (e.g., `test/test_serialize.lua` tests `Util/Serialize.lua`).

## Structure

```lua
-- test/test_serialize.lua
-- (wowstubs and runner globals are loaded automatically by run.lua)

describe("Serialize", function()
    describe("roundTrip", function()
        it("handles a flat table", function()
            local input = { a = 1, b = "hello" }
            local str = ns.Serialize(input)
            expect(ns.Deserialize(str)).toEqual(input)
        end)
    end)
end)
```

## What to Test

- **Util/**: round-trip encode/decode, edge cases (empty, nil, special chars).
- **Core/**: dice formulas, effect pipeline ordering, schema validation & migration.
- **DB/Loader.lua**: locale fallback logic.
- **Comm/Protocol.lua**: message encode/decode round-trips.
- **Import/PasteImport.lua**: decode, validate, reject malformed input.

## What Not to Test Here

- Frame rendering, click handlers, visual layout → in-game `/nagara test`.
- Actual `SendAddonMessage` delivery → manual integration test.

## Assertions

The `expect(value)` function returns an object with these matchers:

- `expect(a).toEqual(b)` — deep equality for tables, strict `==` for scalars.
- `expect(a).toBeNil()` — value is nil.
- `expect(a).toBeTruthy()` / `expect(a).toBeFalsy()`
- `expect(fn).toError()` — function throws when called.
- `expect(a).toContain(b)` — string contains substring, or table contains value.

Add new matchers to `test/run.lua` as needed — keep them minimal.

## Principles

- Write tests **before** implementation where practical (testing-first).
- Each test should be independent — no shared mutable state between `it()` blocks.
- Prefer explicit assertions over "no error thrown."
- Keep `test/run.lua` lean (~125 LOC). Do not over-engineer the runner.
