# Nagara — Data Contracts

> Defines the exact data shapes exchanged between the website and the addon,
> and the internal storage format in SavedVariables.

## 1. Website → Addon Export (Paste-Import String)

The website's "Export for Addon" endpoint should return a **Base64-encoded** serialized Lua table with the following fields. Fields not listed here must be **stripped** by the website before export.

### 1.1 Exported Character Schema

```
{
    id              : string (UUID)         -- unique character ID
    characterName   : string                -- display name
    lastModified    : string (ISO-8601)     -- used for cache freshness
    schemaVersion   : number                -- starts at 1, addon uses for migrations

    experience = {
        total       : number
        unspent     : number
    }

    corruption = {
        permanent   : number
        temporary   : number
    }

    attributes = {
        primary = {
            accurate    : number (1–20)
            cunning     : number
            discreet    : number
            alluring    : number
            quick       : number
            resolute    : number
            vigilant    : number
            strong      : number
        }
        secondary = {
            toughness = {
                max     : number
                current : number
            }
            painThreshold       : number
            corruptionThreshold : number
            defense             : number
        }
    }

    traits      : array of trait objects (may be empty)

    effects     : array of {
        id          : string
        source      : string ("ability" | "spell" | "item" | "ritual" | "rule")
        name        : string
        description : string
        target      : string          -- dotted path, e.g. "rules.defense.base"
        modifier = {
            type    : string          -- "setBase" | "addFlat" | "multiply" | "cap"
            value   : string|number   -- attribute name or numeric amount
        }
        priority    : number          -- lower = applied first
        duration    : number|null     -- null = permanent
    }

    tradition   : string              -- magic tradition name

    equipment = {
        money       : number
        weapons     : array of weapon objects
        ammunition  : array of ammo objects
        armor = {
            body    : array of armor objects
            plug    : array of plug objects
        }
        runes       : array of rune objects
        professional = {
            assassin : array
            utility  : array
        }
        inventory = {
            self    : array of item objects
            home    : array of item objects
        }
        artifacts   : array of artifact objects
    }

    background = {
        race        : string
        shadow      : string
        age         : number
        profession  : string
        journal = {
            open    : array of strings
            done    : array of strings
            rumours : array of strings
        }
        notes       : array of strings
    }

    location    : string
}
```

### 1.2 Fields Intentionally Excluded from Export

These exist in the website's full JSON but are **not needed** by the addon and must be stripped before producing the export string:

| Field                       | Reason                                              |
| --------------------------- | --------------------------------------------------- |
| `playerId`                  | Website-internal identity, not used in-game         |
| `player`                    | Website display name, addon uses WoW character name |
| `backupCode`                | Recovery code, sensitive, not relevant in-game      |
| `created`                   | Informational only; `lastModified` is sufficient    |
| `portrait` (all sub-fields) | Addon does not display images                       |
| `background.portrait`       | Same as above                                       |
| `background.kinkList`       | Not displayed in-addon                              |
| `assets`                    | Duplicate of tradition / not used                   |
| `balance`                   | Website-only economy field                          |

### 1.3 Export Wire Format

```
Base64( Serialize( characterTable ) )
```

Where `Serialize` is the same function used by `Util/Serialize.lua` in the addon.
The website can implement the same serialization algorithm (spec below) or use a compatible format that the addon's deserializer accepts.

**Alternative (simpler for website):** The website can produce a JSON string, the addon Base64-decodes it and runs a tiny JSON→table parser. However, per ADR-006, we prefer no runtime JSON parsing. So the recommended path is: website serializes using the Lua-compatible wire format.

> **Decision needed:** Finalize whether the website emits Lua-serialized or
> JSON. If JSON is simpler for the web team, we can allow a small JSON
> deserializer in `Import/PasteImport.lua` as a build-time-free exception.
> The rest of the addon still has no JSON parsing.

---

## 2. Addon Internal Storage (NagaraDB.characters)

Stored in SavedVariables. Same schema as §1.1 plus these addon-added fields:

```
{
    -- everything from §1.1, plus:
    schemaVersion   : number        -- addon's schema version (for migrations)
    wowCharacter    : string        -- "Name-Realm" this profile is bound to
    importedAt      : number        -- time() when imported
    isActive        : boolean       -- true if this is the currently active profile
}
```

Multiple profiles can exist per WoW character. Only one is `isActive = true`.

---

## 3. Cached Remote Profiles (NagaraDB.cache)

```
NagaraDB.cache["Playername-Realm"] = {
    data        = { ... }           -- same schema as §1.1
    cachedAt    = number            -- time() when last received
    versionHash = string            -- lastModified of the cached version
}
```

Cache entries are pruned on login if `cachedAt` is older than a configurable threshold (default: 90 days).

The DM's cache is also the data source for website sync (see ADR-008): `scripts/sync_upload.py` reads these entries and POSTs changed characters to the website API.

---

## 4. Reverse Paste-Export (Addon → Website Fallback)

Any player can export their active profile via `/nagara export` or the UI "Export" button. The addon produces:

```
Base64( Serialize( activeProfile ) )
```

Same wire format as paste-import (§1.3), same schema as §1.1. The player copies the string and pastes it into the website's "Update from Addon" page.

---

## 5. Website Sync API (DM Script → Website)

```
POST /api/characters/:id/sync
Headers: Authorization: Bearer <dm-token>
Body: { character data matching §1.1 schema }
Response:
  200 OK              — updated
  409 Conflict         — website version is newer (skip, warn)
  401 Unauthorized     — bad token
```

The DM auth token is stored in a local config file (`scripts/.env` or similar), never committed to the repo (`.gitignore`d).

---

## 6. Comm Wire Protocol — Message Types

| msgType (1 byte) | Name               | Direction   | Payload                                      |
| ---------------- | ------------------ | ----------- | -------------------------------------------- |
| `0x01`           | `PROFILE_REQUEST`  | A → B       | `{ versionHash }`                            |
| `0x02`           | `PROFILE_RESPONSE` | B → A       | `{ status = "up-to-date" }`                  |
| `0x03`           | `PROFILE_CHUNK`    | B → A       | chunk of serialized profile                  |
| `0x10`           | `ROLL_RESULT`      | any → party | `{ roller, formula, rolls, total, success }` |
| `0x20`           | `DM_EDIT`          | DM → player | `{ field, value }`                           |
| `0x21`           | `DM_EDIT_ACK`      | player → DM | `{ status, field }`                          |
| `0x22`           | `DM_ROLL_REQUEST`  | DM → player | `{ formula, reason }`                        |

All payloads are serialized via `Util/Serialize.lua` and chunked if >251 bytes.
Envelope format: `[protoVersion:1B][msgType:1B][seqNum:1B][totalChunks:1B][payload]`

> **Note:** DM message types (`0x20`–`0x22`) are defined in the player addon's
> `Comm/Protocol.lua` so the player can handle incoming DM commands.
> The **sending** logic for these messages lives in the separate **NagaraDM** addon.

---

## 5. Static DB Entry Schemas

### 5.1 Ability / Spell (complex)

```lua
{
    id          = "acrobatics",
    name        = "Acrobatics",
    category    = "ability",
    description = "...",
    tags        = { "mobility", "defense", "melee", ... },
    tiers = {
        novice = {
            description = "...",
            effects = {
                { target = "...", action = "...", value = "...", description = "..." },
            },
        },
        adept = { ... },
        master = { ... },
    },
}
```

### 5.2 Ritual (simple)

```lua
{
    id          = "ward-of-light",
    name        = "Ward of Light",
    category    = "ritual",
    tradition   = "Lilies",
    description = "...",
    tags        = { "protection", "light" },
}
```

### 5.3 Talent (simple)

```lua
{
    id          = "contacts",
    name        = "Contacts",
    category    = "talent",
    description = "...",
    tags        = { "social" },
}
```

### 5.4 Item

```lua
{
    id          = "sword-short",
    name        = "Short Sword",
    category    = "item",
    subcategory = "weapon",
    description = "...",
    tags        = { "short-weapon", "melee" },
    properties  = { damage = "d8", quality = {} },
}
```

### 5.5 Rule Text

```lua
{
    id          = "initiative",
    name        = "Initiative",
    category    = "rule",
    description = "Full text of the initiative rule...",
    tags        = { "combat", "turn-order" },
}
```
