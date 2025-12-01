--[[
    Input Handling System
    Centralized keyboard and input management

    Controls mapping:
    - Arrow Left/Right: Rotate ship
    - Arrow Up: Forward thrust
    - Space: Fire railgun
    - P: Pause
    - Escape: Quit
]]

local Input = {}
Input.__index = Input

function Input.new()
    local self = setmetatable({}, Input)

    -- Key states
    self.keys = {
        left = false,
        right = false,
        up = false,
        down = false,
        space = false,
        p = false
    }

    -- Previous frame key states (for detecting key press/release events)
    self.previousKeys = {
        left = false,
        right = false,
        up = false,
        down = false,
        space = false,
        p = false
    }

    return self
end

function Input:update(dt)
    -- Store previous frame state
    for key, state in pairs(self.keys) do
        self.previousKeys[key] = state
    end

    -- Update current key states
    self.keys.left = love.keyboard.isDown("left")
    self.keys.right = love.keyboard.isDown("right")
    self.keys.up = love.keyboard.isDown("up")
    self.keys.down = love.keyboard.isDown("down")
    self.keys.space = love.keyboard.isDown("space")
    self.keys.p = love.keyboard.isDown("p")
end

function Input:isDown(key)
    return self.keys[key] or false
end

function Input:isPressed(key)
    -- Returns true only on the first frame the key is pressed
    return self.keys[key] and not self.previousKeys[key]
end

function Input:isReleased(key)
    -- Returns true only on the first frame the key is released
    return not self.keys[key] and self.previousKeys[key]
end

function Input:keypressed(key, scancode, isrepeat)
    -- Called from love.keypressed callback
    -- Can be used for single-shot inputs
end

function Input:keyreleased(key, scancode)
    -- Called from love.keyreleased callback
end

return Input
