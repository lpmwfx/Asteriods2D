--[[
    AxForge Screenshot Service (AxShot)
    Standard screenshot system for all AxForge LÖVE/LÖVR projects

    Features:
    - Instance-based organization (per project/scene/profile)
    - Hotkey binding (F12 default)
    - Programmatic capture with tags
    - Automatic timestamp and folder management
    - Works in both LÖVE and LÖVR

    Usage:
        local AxShot = require("axforge.axshot")

        -- In love.load():
        AxShot.init{
            instanceId = "asteroids_sdf_dev",
            config = {
                hotkey = "f12",
                folder = "screenshots",
                prefix = "ax",
                addTimestamp = true
            }
        }

        -- In love.keypressed():
        AxShot.handleKey(key)

        -- Programmatic capture:
        AxShot.capture("boss_defeated")
]]

local AxShot = {
    instance = {
        id = "default",
        meta = {}
    },
    config = {
        folder = "screenshots",
        prefix = "shot",
        addTimestamp = true,
        addInstanceToName = false,  -- Use folder for instance separation
        hotkey = nil,               -- e.g. "f12"
    }
}

----------------------------------------------------------------
-- UTILITY FUNCTIONS
----------------------------------------------------------------

local function timestamp()
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

    -- Get absolute path to project directory
    local projectPath = love.filesystem.getSourceBaseDirectory()
    local fullPath = projectPath .. "/" .. base

    -- Create directory using OS command (love.filesystem can't create outside save dir)
    os.execute('mkdir -p "' .. fullPath .. '"')

    return fullPath
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
        table.insert(parts, timestamp())
    end

    return table.concat(parts, "_") .. ".png"
end

----------------------------------------------------------------
-- LÖVE BACKEND
----------------------------------------------------------------

local function captureLove(filepath)
    -- LÖVE 11.x uses captureScreenshot with callback
    love.graphics.captureScreenshot(function(imageData)
        -- Encode to FileData (in memory, not to disk yet)
        local fileData = imageData:encode("png")

        -- Write to actual filesystem using io.open (not love.filesystem)
        local file = io.open(filepath, "wb")
        if file then
            file:write(fileData:getString())
            file:close()
            print("[AxShot] Screenshot saved: " .. filepath)
        else
            print("[AxShot] Failed to save screenshot: " .. filepath)
        end
    end)
end

----------------------------------------------------------------
-- LÖVR BACKEND (sketch - adjust for your LÖVR version)
----------------------------------------------------------------

local function captureLovr(filepath)
    -- PSEUDO: Check against your LÖVR version
    local w, h = lovr.graphics.getWidth(), lovr.graphics.getHeight()
    local pixels = lovr.graphics.readPixels(0, 0, w, h)

    -- Use your preferred PNG writing method
    local ok, err = lovr.filesystem.write(filepath, pixels)
    if not ok then
        print("[AxShot] Failed to write screenshot: " .. tostring(err))
    else
        print("[AxShot] Screenshot saved: " .. filepath)
    end
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

--[[
    Initialize AxShot with instance and config

    @param opts table {
        instanceId: string (optional) - Project/scene identifier
        instanceMeta: table (optional) - Additional metadata
        config: table (optional) - Configuration overrides
    }
]]
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

    print("[AxShot] Initialized with instance: " .. AxShot.instance.id)
    print("[AxShot] Screenshots folder: " .. baseFolder())
    if AxShot.config.hotkey then
        print("[AxShot] Hotkey: " .. AxShot.config.hotkey)
    end
end

--[[
    Change instance on the fly (scene, level, profile)

    @param id string - New instance identifier
    @param meta table (optional) - Instance metadata
]]
function AxShot.setInstance(id, meta)
    AxShot.instance.id = id or "default"
    AxShot.instance.meta = meta or {}
    print("[AxShot] Instance changed to: " .. AxShot.instance.id)
end

--[[
    Capture screenshot

    @param tag string (optional) - Tag for filename (e.g. "boss_room" or "bug_123")
    @param meta table (optional) - Additional metadata (can be logged later)
    @return string - Filepath of saved screenshot
]]
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

    -- TODO: Add JSON log with metadata here
    -- AxShot._logCapture(filepath, meta)

    return filepath
end

--[[
    Handle key press for hotkey binding
    Call this from love.keypressed / lovr.keypressed

    @param key string - Key that was pressed
]]
function AxShot.handleKey(key)
    if AxShot.config.hotkey and key == AxShot.config.hotkey then
        AxShot.capture()
    end
end

--[[
    Get current configuration

    @return table - Current config
]]
function AxShot.getConfig()
    return AxShot.config
end

--[[
    Get current instance info

    @return table - Current instance
]]
function AxShot.getInstance()
    return AxShot.instance
end

return AxShot
