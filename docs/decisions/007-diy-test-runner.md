# ADR-007: DIY Test Runner Instead of Busted

**Status:** Accepted (supersedes busted references in ADR-005)  
**Date:** 2026-03-31  
**Deciders:** Project owner + Copilot design session

## Context

ADR-005 originally specified `busted` (a Lua test framework installed via luarocks) as the test runner. While `busted` is a dev-time dependency and never ships in the addon, it still introduces an external tool with its own dependency chain (luarocks, luafilesystem, penlight, mediator, etc.).

This conflicts with the project's philosophical commitment to self-contained tooling and complicates CI setup.

## Decision

Replace `busted` with a **hand-written test runner** in `test/run.lua`.

The runner provides:

| Feature                                                | Approx. LOC |
| ------------------------------------------------------ | ----------- |
| `describe(name, fn)` / `it(name, fn)` — test structure | ~30         |
| `expect(val).toEqual(...)` etc. — assertions           | ~40         |
| `beforeEach` / `afterEach` — setup/teardown            | ~15         |
| File discovery, pass/fail counting, exit code          | ~40         |

**Total: ~125 lines of Lua.**

### What We Don't Need

- Mocking framework — our tests are pure-function round-trips.
- Async test support — all code is synchronous.
- Code coverage — project is small enough for manual coverage assessment.
- Parameterized tests — explicit test cases are clearer at this scale.
- Multiple output formatters — plain text to stdout is sufficient.

### Runner Interface

```lua
-- test/run.lua
-- Invoked as: lua test/run.lua
-- Exit code 0 = all passed, 1 = any failures.
```

Test files use the same `describe` / `it` / `expect` pattern:

```lua
describe("Base64", function()
    it("round-trips a simple string", function()
        local encoded = Base64.encode("hello")
        expect(Base64.decode(encoded)).toEqual("hello")
    end)
end)
```

### CI

```yaml
steps:
  - uses: actions/checkout@v4
  - run: sudo apt-get install -y lua5.1
  - run: lua5.1 test/run.lua
```

No third-party actions, no luarocks — just an OS package and our runner.

## Consequences

- **Positive:** CI needs only a Lua 5.1 interpreter — simpler, faster.
- **Positive:** Full control over test output formatting and behavior.
- **Positive:** Philosophically consistent with zero-dependency approach.
- **Positive:** ~125 LOC is less overhead than configuring busted + luarocks.
- **Negative:** Must maintain the runner ourselves. Acceptable at this scale — the runner is simple and unlikely to need changes once written.
- **Negative:** No ecosystem of plugins (coverage, TAP output, etc.). Not needed for this project.
