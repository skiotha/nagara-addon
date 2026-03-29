---
applyTo: "test/**"
---

# Test Conventions

## Framework

- Tests run outside WoW with **Lua 5.1 + busted**.
- WoW API stubs live in `test/wowstubs.lua` — loaded before any addon file.
- Tests should never require the actual WoW client or network.

## File Naming

- One test file per module: `test/test_<module>.lua`
  (e.g., `test/test_serialize.lua` tests `Util/Serialize.lua`).

## Structure

```lua
require("test.wowstubs")
-- load the module under test

describe("ModuleName", function()
    describe("FunctionName", function()
        it("does specific thing", function()
            -- arrange / act / assert
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

## Principles

- Write tests **before** implementation where practical (testing-first).
- Each test should be independent — no shared mutable state between `it()` blocks.
- Prefer explicit assertions over "no error thrown."
