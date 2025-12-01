-- src/core/display.lua
-- Fullscreen and display management system
-- Handles resolution detection, fullscreen toggling, and window resize events

local Display = {}

-- Supported resolutions (up to 2560x1440 - 2K max)
Display.SUPPORTED_RESOLUTIONS = {
    {width = 1280, height = 720},   -- HD
    {width = 1920, height = 1080},  -- Full HD
    {width = 2560, height = 1440},  -- 2K
}

-- Maximum supported resolution
Display.MAX_WIDTH = 2560
Display.MAX_HEIGHT = 1440

-- Current display state
Display.isFullscreen = false
Display.currentWidth = 0
Display.currentHeight = 0
Display.windowedWidth = 1280
Display.windowedHeight = 720

-- DPI scale factor
Display.dpiScale = 1.0

-- Initialize display system
function Display:init()
    self:detectDPI()
    self:updateCurrentDimensions()

    -- Check if we're already in fullscreen mode (from conf.lua)
    self.isFullscreen = love.window.getFullscreen()
end

-- Detect DPI scale factor
function Display:detectDPI()
    self.dpiScale = love.window.getDPIScale()
end

-- Get monitor resolution
function Display:getMonitorResolution()
    -- Get all display modes for the current monitor
    local modes = love.window.getFullscreenModes()

    if not modes or #modes == 0 then
        -- Fallback to default if no modes detected
        return 1920, 1080
    end

    -- Find the largest resolution (usually native)
    local maxWidth = 0
    local maxHeight = 0

    for _, mode in ipairs(modes) do
        if mode.width > maxWidth then
            maxWidth = mode.width
            maxHeight = mode.height
        end
    end

    return maxWidth, maxHeight
end

-- Select best resolution for fullscreen (closest to 2K max)
function Display:selectBestResolution()
    local monitorWidth, monitorHeight = self:getMonitorResolution()

    -- Cap at our maximum supported resolution
    local targetWidth = math.min(monitorWidth, self.MAX_WIDTH)
    local targetHeight = math.min(monitorHeight, self.MAX_HEIGHT)

    -- Find closest supported resolution
    local bestRes = self.SUPPORTED_RESOLUTIONS[1]
    local minDiff = math.huge

    for _, res in ipairs(self.SUPPORTED_RESOLUTIONS) do
        local diff = math.abs(res.width - targetWidth) + math.abs(res.height - targetHeight)
        if diff < minDiff then
            minDiff = diff
            bestRes = res
        end
    end

    return bestRes.width, bestRes.height
end

-- Update current window dimensions
function Display:updateCurrentDimensions()
    self.currentWidth, self.currentHeight = love.graphics.getDimensions()
end

-- Toggle fullscreen mode
function Display:toggleFullscreen()
    self.isFullscreen = not self.isFullscreen
    self:setFullscreen(self.isFullscreen)
end

-- Set fullscreen mode
function Display:setFullscreen(enabled)
    self.isFullscreen = enabled

    if enabled then
        -- Switch to fullscreen with best resolution
        local width, height = self:selectBestResolution()
        love.window.setMode(width, height, {
            fullscreen = true,
            fullscreentype = "desktop",  -- Borderless fullscreen (faster switching)
            resizable = false,
            highdpi = true,
        })
    else
        -- Switch to windowed mode
        love.window.setMode(self.windowedWidth, self.windowedHeight, {
            fullscreen = false,
            resizable = true,
            highdpi = true,
        })
    end

    self:updateCurrentDimensions()
end

-- Handle window resize event
function Display:handleResize(width, height)
    self.currentWidth = width
    self.currentHeight = height

    -- Store windowed dimensions for later
    if not self.isFullscreen then
        self.windowedWidth = width
        self.windowedHeight = height
    end
end

-- Get current display mode info
function Display:getInfo()
    return {
        width = self.currentWidth,
        height = self.currentHeight,
        fullscreen = self.isFullscreen,
        dpiScale = self.dpiScale,
    }
end

-- Get DPI scale factor
function Display:getDPIScale()
    return self.dpiScale
end

-- Check if ultrawide aspect ratio (21:9 or wider)
function Display:isUltrawide()
    local aspect = self.currentWidth / self.currentHeight
    return aspect >= 2.1  -- 21:9 = 2.333
end

-- Get aspect ratio
function Display:getAspectRatio()
    return self.currentWidth / self.currentHeight
end

return Display
