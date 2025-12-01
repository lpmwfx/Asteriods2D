--[[
    Game State Management
    Handles game states: menu, playing, paused, game_over

    Responsibilities:
    - State transitions
    - Entity lifecycle management
    - Score and lives tracking
    - Meteor spawning coordination
]]

local GameState = {}
GameState.__index = GameState

-- Game states enum
local States = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    GAME_OVER = "game_over"
}

function GameState.new(physics, input)
    local self = setmetatable({}, GameState)

    self.physics = physics
    self.input = input

    -- Current state
    self.state = States.MENU

    -- Game metrics
    self.score = 0
    self.lives = 3
    self.meteorsDestroyed = 0

    -- Entities (will be populated when entities are implemented)
    self.ship = nil
    self.meteors = {}
    self.railgunBeams = {}

    -- Spawning system
    self.spawnTimer = 0
    self.spawnInterval = 2.0  -- Seconds between spawns
    self.maxMeteors = 10

    -- Protected zone
    self.protectedZoneRadius = 150

    print("GameState initialized in state: " .. self.state)

    return self
end

function GameState:update(dt)
    if self.state == States.PLAYING then
        self:updatePlaying(dt)
    elseif self.state == States.MENU then
        self:updateMenu(dt)
    elseif self.state == States.PAUSED then
        -- Paused state - no updates
    elseif self.state == States.GAME_OVER then
        self:updateGameOver(dt)
    end
end

function GameState:updateMenu(dt)
    -- Check for start game input
    if self.input:isPressed("space") then
        self:startGame()
    end
end

function GameState:updatePlaying(dt)
    -- Update ship
    if self.ship then
        self.ship:update(dt)
    end

    -- Update meteors
    for i = #self.meteors, 1, -1 do
        local meteor = self.meteors[i]
        meteor:update(dt)

        -- Remove destroyed meteors
        if meteor.destroyed then
            table.remove(self.meteors, i)
        end
    end

    -- Update railgun beams (visual effects)
    for i = #self.railgunBeams, 1, -1 do
        local beam = self.railgunBeams[i]
        beam:update(dt)

        if beam.finished then
            table.remove(self.railgunBeams, i)
        end
    end

    -- Meteor spawning
    self:updateSpawning(dt)

    -- Check game over conditions
    if self.lives <= 0 then
        self:gameOver()
    end
end

function GameState:updateGameOver(dt)
    -- Check for restart input
    if self.input:isPressed("space") then
        self:startGame()
    end
end

function GameState:updateSpawning(dt)
    -- Spawn meteors periodically
    self.spawnTimer = self.spawnTimer + dt

    if self.spawnTimer >= self.spawnInterval and #self.meteors < self.maxMeteors then
        self:spawnMeteor()
        self.spawnTimer = 0
    end
end

function GameState:spawnMeteor()
    -- Placeholder: actual spawning will be implemented with Meteor entity
    print("Spawning meteor (not implemented yet)")
end

function GameState:draw()
    if self.state == States.MENU then
        self:drawMenu()
    elseif self.state == States.PLAYING then
        self:drawPlaying()
    elseif self.state == States.PAUSED then
        self:drawPlaying()  -- Draw game in background
        self:drawPauseOverlay()
    elseif self.state == States.GAME_OVER then
        self:drawPlaying()  -- Draw final state
        self:drawGameOverOverlay()
    end
end

function GameState:drawMenu()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "AxiumForge - SDF Asteroids\n\nPress SPACE to start",
        0,
        love.graphics.getHeight() / 2 - 50,
        love.graphics.getWidth(),
        "center"
    )
end

function GameState:drawPlaying()
    -- Draw protected zone
    self:drawProtectedZone()

    -- Draw meteors
    for _, meteor in ipairs(self.meteors) do
        meteor:draw()
    end

    -- Draw ship
    if self.ship then
        self.ship:draw()
    end

    -- Draw railgun beams
    for _, beam in ipairs(self.railgunBeams) do
        beam:draw()
    end
end

function GameState:drawProtectedZone()
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2

    -- Draw circle outline
    love.graphics.setColor(0.3, 0.5, 1.0, 0.3)
    love.graphics.circle("line", cx, cy, self.protectedZoneRadius)

    -- Draw glow effect
    love.graphics.setColor(0.3, 0.5, 1.0, 0.1)
    love.graphics.circle("line", cx, cy, self.protectedZoneRadius + 2)
    love.graphics.circle("line", cx, cy, self.protectedZoneRadius - 2)
end

function GameState:drawPauseOverlay()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "PAUSED\n\nPress P to resume",
        0,
        love.graphics.getHeight() / 2 - 30,
        love.graphics.getWidth(),
        "center"
    )
end

function GameState:drawGameOverOverlay()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        "GAME OVER\n\nScore: " .. self.score .. "\nMeteors Destroyed: " .. self.meteorsDestroyed .. "\n\nPress SPACE to restart",
        0,
        love.graphics.getHeight() / 2 - 60,
        love.graphics.getWidth(),
        "center"
    )
end

function GameState:startGame()
    print("Starting game...")
    self.state = States.PLAYING
    self.score = 0
    self.lives = 3
    self.meteorsDestroyed = 0
    self.meteors = {}
    self.railgunBeams = {}
    self.spawnTimer = 0

    -- TODO: Initialize ship and other entities
end

function GameState:togglePause()
    if self.state == States.PLAYING then
        self.state = States.PAUSED
        print("Game paused")
    elseif self.state == States.PAUSED then
        self.state = States.PLAYING
        print("Game resumed")
    end
end

function GameState:gameOver()
    print("Game over! Score: " .. self.score)
    self.state = States.GAME_OVER
end

function GameState:addScore(points)
    self.score = self.score + points
end

function GameState:loseLife()
    self.lives = self.lives - 1
    print("Life lost! Remaining: " .. self.lives)
end

return GameState
