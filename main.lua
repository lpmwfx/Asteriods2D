--[[
    AxiumForge - SDF Asteroids
    Main game entry point

    This file contains the core LÖVE callbacks and initializes all game systems.
]]

-- AxForge standard modules
local AxShot = require("axforge.axshot")

-- Module dependencies
local Viewport = require("src.core.viewport")
local Display = require("src.core.display")
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

    -- Initialize AxForge services
    AxShot.init{
        instanceId = "asteroids_sdf_dev",
        config = {
            hotkey = "f12",
            folder = "screenshots",
            prefix = "axforge",
            addTimestamp = true
        }
    }

    -- Initialize graphics settings
    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("miter")

    -- Initialize display and viewport systems (FASE 2)
    Display:init()
    Viewport:init()

    -- Initialize core systems
    physics = Physics.new()
    input = Input.new()
    gameState = GameState.new(physics, input)

    -- Initialize rendering systems
    background = Background.new()
    ui = UI.new()

    print("AxiumForge - SDF Asteroids initialized successfully")
    print("Window size: " .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight())
    print("Virtual resolution: " .. Viewport.VIRTUAL_WIDTH .. "x" .. Viewport.VIRTUAL_HEIGHT)
    print("Fullscreen: " .. tostring(Display.isFullscreen))
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

    -- Update UI elements with game state data
    ui:setScore(gameState.score)
    ui:setLives(gameState.lives)
    ui:setMeteorCount(#gameState.meteors)
    ui:setRailgunCooldown(gameState.railgun.cooldown)
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

    -- Draw letterbox/pillarbox bars if needed
    Viewport:drawLetterbox()

    -- Apply viewport transform for resolution-independent rendering
    Viewport:applyTransform()

    -- Draw background (solar system with parallax)
    background:draw()

    -- Draw game state (meteors, ship, effects)
    gameState:draw()

    -- Draw UI overlay (score, shields, etc.)
    ui:draw()

    -- Reset viewport transform
    Viewport:resetTransform()
end

--[[
    love.keypressed(key)
    Called when a key is pressed.
    @param key - The key that was pressed
]]
function love.keypressed(key, scancode, isrepeat)
    -- AxForge services
    AxShot.handleKey(key)

    -- Game input
    input:keypressed(key, scancode, isrepeat)

    -- Global controls
    if key == "escape" then
        love.event.quit()
    end

    if key == "p" then
        gameState:togglePause()
    end

    -- Fullscreen toggle (F11) - FASE 2
    if key == "f11" then
        Display:toggleFullscreen()
        Viewport:updateDimensions()
        print("Fullscreen: " .. tostring(Display.isFullscreen))
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
    love.resize(w, h)
    Called when the window is resized.
    @param w - New window width
    @param h - New window height
]]
function love.resize(w, h)
    -- Update display and viewport systems
    Display:handleResize(w, h)
    Viewport:updateDimensions()
    print("Window resized to: " .. w .. "x" .. h)
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
