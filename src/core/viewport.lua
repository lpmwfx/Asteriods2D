-- src/core/viewport.lua
-- Virtual resolution system for resolution-independent rendering
-- Provides coordinate transformation between virtual and screen space

local Viewport = {}

-- Virtual base resolution (1920x1080 - Full HD as design target)
Viewport.VIRTUAL_WIDTH = 1920
Viewport.VIRTUAL_HEIGHT = 1080

-- Current window dimensions
Viewport.screenWidth = 0
Viewport.screenHeight = 0

-- Scaling factors
Viewport.scaleX = 1
Viewport.scaleY = 1
Viewport.scale = 1  -- Uniform scale (minimum of scaleX and scaleY)

-- Offset for letterboxing/pillarboxing
Viewport.offsetX = 0
Viewport.offsetY = 0

-- Initialize viewport with current window dimensions
function Viewport:init()
    self:updateDimensions()
end

-- Update viewport dimensions (call on window resize)
function Viewport:updateDimensions()
    self.screenWidth, self.screenHeight = love.graphics.getDimensions()

    -- Calculate scale factors
    self.scaleX = self.screenWidth / self.VIRTUAL_WIDTH
    self.scaleY = self.screenHeight / self.VIRTUAL_HEIGHT

    -- Use uniform scaling (maintain aspect ratio)
    self.scale = math.min(self.scaleX, self.scaleY)

    -- Calculate letterbox/pillarbox offsets to center the viewport
    local scaledWidth = self.VIRTUAL_WIDTH * self.scale
    local scaledHeight = self.VIRTUAL_HEIGHT * self.scale

    self.offsetX = (self.screenWidth - scaledWidth) / 2
    self.offsetY = (self.screenHeight - scaledHeight) / 2
end

-- Get current uniform scale factor
function Viewport:getScale()
    return self.scale
end

-- Get scale factors (X and Y separately)
function Viewport:getScaleFactors()
    return self.scaleX, self.scaleY
end

-- Get virtual dimensions
function Viewport:getVirtualDimensions()
    return self.VIRTUAL_WIDTH, self.VIRTUAL_HEIGHT
end

-- Get screen dimensions
function Viewport:getScreenDimensions()
    return self.screenWidth, self.screenHeight
end

-- Get letterbox/pillarbox offsets
function Viewport:getOffsets()
    return self.offsetX, self.offsetY
end

-- Convert screen coordinates to virtual coordinates
function Viewport:toVirtual(screenX, screenY)
    local virtualX = (screenX - self.offsetX) / self.scale
    local virtualY = (screenY - self.offsetY) / self.scale
    return virtualX, virtualY
end

-- Convert virtual coordinates to screen coordinates
function Viewport:toScreen(virtualX, virtualY)
    local screenX = virtualX * self.scale + self.offsetX
    local screenY = virtualY * self.scale + self.offsetY
    return screenX, screenY
end

-- Apply viewport transform for rendering
-- Call this at the start of love.draw() before rendering game content
function Viewport:applyTransform()
    love.graphics.push()
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale, self.scale)
end

-- Remove viewport transform
-- Call this after rendering game content
function Viewport:resetTransform()
    love.graphics.pop()
end

-- Draw letterbox/pillarbox bars (black bars for aspect ratio mismatch)
function Viewport:drawLetterbox()
    love.graphics.setColor(0, 0, 0, 1)

    -- Top/bottom bars (letterbox)
    if self.offsetY > 0 then
        love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.offsetY)
        love.graphics.rectangle("fill", 0, self.screenHeight - self.offsetY, self.screenWidth, self.offsetY)
    end

    -- Left/right bars (pillarbox)
    if self.offsetX > 0 then
        love.graphics.rectangle("fill", 0, 0, self.offsetX, self.screenHeight)
        love.graphics.rectangle("fill", self.screenWidth - self.offsetX, 0, self.offsetX, self.screenHeight)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Check if point (in virtual coordinates) is visible
function Viewport:isVisible(virtualX, virtualY, margin)
    margin = margin or 0
    return virtualX >= -margin and virtualX <= self.VIRTUAL_WIDTH + margin and
           virtualY >= -margin and virtualY <= self.VIRTUAL_HEIGHT + margin
end

-- Get virtual center coordinates
function Viewport:getCenter()
    return self.VIRTUAL_WIDTH / 2, self.VIRTUAL_HEIGHT / 2
end

return Viewport
