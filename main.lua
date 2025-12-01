--[[
    AxiumForge - SDF Asteroids
    Main game entry point

    This file contains the core LÖVE callbacks and initializes all game systems.
]]

-- Module dependencies
local GameState = require("src.core.game_state")
local Physics = require("src.core.physics")
local Input = require("src.core.input")
local Background = require("src.render.background")
local UI = require("src.render.ui")

-- Game state
local gameState = nil
local physics = nil
local input = nil
local background = nil
local ui = nil

--[[
    love.load()
    Called once at the start of the game.
    Initialize all game systems here.
]]
function love.load()
    -- Set random seed
    math.randomseed(os.time())

    -- Initialize graphics settings
    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("miter")

    -- Initialize core systems
    physics = Physics.new()
    input = Input.new()
    gameState = GameState.new(physics, input)

    -- Initialize rendering systems
    background = Background.new()
    ui = UI.new()

    print("AxiumForge - SDF Asteroids initialized successfully")
    print("Window size: " .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight())
end

--[[
    love.update(dt)
    Called every frame. Update game logic here.
    @param dt - Delta time in seconds since last frame
]]
function love.update(dt)
    -- Update input state
    input:update(dt)

    -- Update physics world
    physics:update(dt)

    -- Update game state (entities, spawning, collision detection)
    gameState:update(dt)

    -- Update background animation
    background:update(dt)

    -- Update UI elements
    ui:update(dt)
end

--[[
    love.draw()
    Called every frame after update. Render graphics here.
    NO GAME LOGIC should be in this function.
]]
function love.draw()
    -- Clear screen with space background color
    love.graphics.clear(0.02, 0.02, 0.05, 1.0)

    -- Draw background (solar system with parallax)
    background:draw()

    -- Draw game state (meteors, ship, effects)
    gameState:draw()

    -- Draw UI overlay (score, shields, etc.)
    ui:draw()
end

--[[
    love.keypressed(key)
    Called when a key is pressed.
    @param key - The key that was pressed
]]
function love.keypressed(key, scancode, isrepeat)
    input:keypressed(key, scancode, isrepeat)

    -- Global controls
    if key == "escape" then
        love.event.quit()
    end

    if key == "p" then
        gameState:togglePause()
    end
end

--[[
    love.keyreleased(key)
    Called when a key is released.
    @param key - The key that was released
]]
function love.keyreleased(key, scancode)
    input:keyreleased(key, scancode)
end

--[[
    love.quit()
    Called when the game is closing.
    Clean up resources here.
]]
function love.quit()
    print("Shutting down AxiumForge - SDF Asteroids")
    -- Cleanup physics world
    if physics then
        physics:destroy()
    end
end
