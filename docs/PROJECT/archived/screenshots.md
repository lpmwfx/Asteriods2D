Fedt – lad os gøre “screenshot” til en **AxForge-standard**, som AI-agenter kan forstå og bruge automatisk 🤝

Jeg laver:

1. **Koncept**: Hvad er *AxForge Screenshot Service* (AxShot)
2. **Standard struktur i projektet**
3. **Lua-lib: `axforge/axshot.lua`** (LÖVE + LÖVR, instance-styret)
4. **Config pr. instance** (så AI/”MCP” kan styre det)
5. **MCP-/AI-kontrakt** (hvordan AI-coder skal bruge det)

---

## 1. Koncept: AxForge Screenshot Service (AxShot)

Idéen:

* Alle AxForge-projekter har **den samme lille lib** til screenshots.
* Hver kørende spil/scene har en **instance-id** (f.eks. `"asteroids_sdf_dev"`)
* Screenshots går i:
  `screenshots/<instance-id>/<pattern>.png`
* AI-agenter (Claude, GPT, osv) ved, at de:

  * **aldrig selv opfinder screenshot-kode**,
  * men **ALTID bruger `AxShot.capture(...)`** og evt. `AxShot.bindHotkey(...)`.

---

## 2. Standard projektstruktur

Foreslået AxForge standard:

```text
project/
  main.lua           -- love/lovr entry
  axforge/
    axshot.lua       -- fælles lib
    axshot.config.json  -- (valgfri) default config
  screenshots/
    (autolavet)
```

På sigt kan du smide flere ting i `axforge/` (log, profiler osv.)

---

## 3. Lua-lib: `axforge/axshot.lua`

> Bemærk: LÖVR-delen er lidt pseudo, fordi præcis pixel/encode-API kan variere – men strukturen er den vigtige del af standarden. Du kan finpudse den til din LÖVR-version.

```lua
-- axforge/axshot.lua
local AxShot = {
  instance = {
    id = "default",
    meta = {}
  },
  config = {
    folder = "screenshots",
    prefix = "shot",
    addTimestamp = true,
    addInstanceToName = false, -- vi bruger mappen til instance
    hotkey = nil,              -- f.eks. "f12"
  }
}

----------------------------------------------------------------
-- UTIL
----------------------------------------------------------------
local function ts()
  return os.date("%Y-%m-%d_%H-%M-%S")
end

local function merge(into, from)
  if not from then return into end
  for k, v in pairs(from) do
    into[k] = v
  end
  return into
end

local function baseFolder()
  local base = AxShot.config.folder or "screenshots"
  if AxShot.instance.id then
    base = base .. "/" .. AxShot.instance.id
  end
  if love and love.filesystem then
    love.filesystem.createDirectory(base)
  elseif lovr and lovr.filesystem then
    lovr.filesystem.createDirectory(base)
  end
  return base
end

local function buildFilename(tag)
  local parts = {}
  table.insert(parts, AxShot.config.prefix or "shot")

  if AxShot.config.addInstanceToName and AxShot.instance.id then
    table.insert(parts, AxShot.instance.id)
  end

  if tag and #tag > 0 then
    table.insert(parts, tag)
  end

  if AxShot.config.addTimestamp then
    table.insert(parts, ts())
  end

  return table.concat(parts, "_") .. ".png"
end

----------------------------------------------------------------
-- LÖVE BACKEND
----------------------------------------------------------------
local function captureLove(filepath)
  love.graphics.captureScreenshot(filepath)
end

----------------------------------------------------------------
-- LÖVR BACKEND (skitse)
----------------------------------------------------------------
local function captureLovr(filepath)
  -- PSEUDO: tjek mod din LÖVR version
  local w, h = lovr.graphics.getWidth(), lovr.graphics.getHeight()
  local pixels = lovr.graphics.readPixels(0, 0, w, h)

  -- Her skal du bruge din foretrukne måde at skrive PNG på.
  -- Fx via et C/FFI modul eller lovr.data image-encode.
  -- For AxForge-standarden er det nok at sige:
  local ok, err = lovr.filesystem.write(filepath, pixels)
  if not ok then
    print("[AxShot] Failed to write screenshot:", err)
  end
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

--- Init med instance og config
-- opts = {
--   instanceId = "asteroids_sdf_dev",
--   instanceMeta = {...},
--   config = {...}
-- }
function AxShot.init(opts)
  opts = opts or {}
  if opts.instanceId then
    AxShot.instance.id = opts.instanceId
  end
  if opts.instanceMeta then
    AxShot.instance.meta = opts.instanceMeta
  end
  if opts.config then
    merge(AxShot.config, opts.config)
  end
end

--- Skift instance on the fly (scene, level, profil)
function AxShot.setInstance(id, meta)
  AxShot.instance.id = id or "default"
  AxShot.instance.meta = meta or {}
end

--- Capture screenshot
-- tag: string (valgfri, fx "boss_room" eller "bug_123")
-- meta: tabel (valgfri, fx camera pos osv. – kan logges senere)
function AxShot.capture(tag, meta)
  local folder = baseFolder()
  local filename = buildFilename(tag)
  local filepath = folder .. "/" .. filename

  if lovr then
    captureLovr(filepath)
  elseif love then
    captureLove(filepath)
  else
    error("[AxShot] Unknown runtime (not LÖVE/LÖVR)")
  end

  print(("[AxShot] %s"):format(filepath))

  -- TODO: Du kan tilføje log til JSON/DB med meta her
  -- AxShot._logCapture(filepath, meta)

  return filepath
end

--- Bind en hotkey: kald denne fra love.keypressed / lovr.keypressed
function AxShot.handleKey(key)
  if AxShot.config.hotkey and key == AxShot.config.hotkey then
    AxShot.capture()
  end
end

return AxShot
```

---

## 4. Instance-styret brug i LÖVE og LÖVR

### LÖVE: `main.lua`

```lua
local AxShot = require "axforge.axshot"

function love.load()
  AxShot.init{
    instanceId = "asteroids_sdf_dev",
    config = {
      hotkey = "f12",
      folder = "screenshots",
      prefix = "ax",
      addTimestamp = true
    }
  }
end

function love.keypressed(key)
  AxShot.handleKey(key)

  if key == "escape" then
    love.event.quit()
  end
end
```

### LÖVR: `main.lua`

```lua
local AxShot = require "axforge.axshot"

function lovr.load()
  AxShot.init{
    instanceId = "lovr_asteroids_sdf_dev",
    config = {
      hotkey = "f12"
    }
  }
end

function lovr.keypressed(key)
  AxShot.handleKey(key)
end
```

Nu er **instance-styret**:

* Skift scene: `AxShot.setInstance("world_02_boss", { difficulty = "hard" })`
* Billeder lander i `screenshots/world_02_boss/*.png`

---

## 5. AI / “MCP”-kontrakt (hvordan AI-coder skal bruge det)

Hvis vi tænker “MCP” som: *en standard “tool”-beskrivelse AI-agenter følger*, kan du sige:

> **Alle AxForge-projekter har altid `axforge/axshot.lua` og AI må KUN bruge dette interface til screenshots.**

### 5.1. Minimal “tool spec” til AI-agenter

I dine AI-prompts / RAG-docs kan du have noget i denne stil:

```json
{
  "name": "AxForge.AxShot",
  "description": "Standard screenshot service for all AxForge LÖVE/LÖVR projects.",
  "api": {
    "lua_module": "axforge.axshot",
    "functions": {
      "init": {
        "params": {
          "instanceId": "string (optional)",
          "instanceMeta": "table (optional)",
          "config": "table (optional)"
        }
      },
      "setInstance": {
        "params": {
          "id": "string",
          "meta": "table (optional)"
        }
      },
      "capture": {
        "params": {
          "tag": "string (optional)",
          "meta": "table (optional)"
        },
        "returns": "filepath (string)"
      },
      "handleKey": {
        "params": {
          "key": "string"
        }
      }
    }
  }
}
```

Og i en “AI-kode-stil-guide” kunne du skrive:

* **Når du laver nye LÖVE/LÖVR-projekter**:

  * `require "axforge.axshot"` i toppen.
  * Kald `AxShot.init{ instanceId = "<project_name>_dev" }` i `love.load`/`lovr.load`.
  * Kald `AxShot.handleKey(key)` i `love.keypressed`/`lovr.keypressed`.
* **Hvis du skal tage screenshots programmatisk** (debug, tests):

  * Brug `AxShot.capture("tag")` i stedet for custom kode.

---

## 6. Hvad vi har nu

Du har nu en **AxForge-standard**:

* 📁 Fast **mappestruktur** (`axforge/`, `screenshots/`)
* 📦 Et **fælles Lua-modul `axshot.lua`** der:

  * virker i både LÖVE og LÖVR (med minimal backend forskel)
  * er **instance-styret** (per projekt/scene/profil)
  * har hotkey-binding og programmatisk `capture()`
* 🧠 En simpel **AI-/MCP-kontrakt**, så alle dine AI-coders ved:

  * hvordan de skal integrere screenshots
  * at de ikke må opfinde egen ad-hoc screenshot-kode

---

Hvis du vil, kan næste skridt være:

* En lille **`axshot.config.json`-standard** (så AI bare skriver config-filen).
* En **logfil pr. screenshot** (JSON ved siden af PNG) med camera-pos, seed, osv → perfekt til SDF/TSDF debugging.
* En “AxForge Dev HUD”, hvor `F12` ikke bare tager screenshot, men også viser en lille overlay med instance-info.

Sig til hvad du vil tage fat i først, så designer vi den også som standard 💾🧩
