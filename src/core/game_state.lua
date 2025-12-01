--[[
    Game State Management
    Handles game states: menu, playing, paused, game_over

    Responsibilities:
    - State transitions
    - Entity lifecycle management
    - Score and lives tracking
    - Meteor spawning coordination
]]

local Ship = require("src.entities.ship")
local Meteor = require("src.entities.meteor")
local Railgun = require("src.entities.railgun")
local MeteorData = require("src.data.sdf_meteors")
local Settings = require("src.data.settings")

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

    -- Entities
    self.ship = nil
    self.meteors = {}
    self.railgun = Railgun.new()

    -- Spawning system
    self.spawnTimer = 0
    self.spawnInterval = 2.0  -- Seconds between spawns
    self.maxMeteors = 10

    -- Protected zone
    self.protectedZoneRadius = 150

    -- Deferred actions (to avoid Box2D locking issues)
    self.deferredRespawn = false

    -- Register collision callbacks
    self:setupCollisionCallbacks()

    print("GameState initialized in state: " .. self.state)

    return self
end

function GameState:setupCollisionCallbacks()
    -- Ship collision with meteors
    self.physics:registerCollisionCallback("ship", function(shipData, otherData, contact)
        if otherData and otherData.type == "meteor" then
            -- Ship hit meteor - take damage
            if shipData.entity and shipData.entity.alive then
                print("Ship collided with meteor!")
                shipData.entity:takeDamage()
                self:loseLife()
            end
        end
    end)

    -- Meteor collision with ship (reverse direction)
    self.physics:registerCollisionCallback("meteor", function(meteorData, otherData, contact)
        if otherData and otherData.type == "ship" then
            -- Meteor hit ship - destroy meteor
            if meteorData.entity and not meteorData.entity.destroyed then
                meteorData.entity:destroy()
            end
        end
    end)
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
        self.ship:update(dt, self.input)
    end

    -- Update meteors
    for i = #self.meteors, 1, -1 do
        local meteor = self.meteors[i]
        meteor:update(dt)

        -- Check if meteor crossed protected zone
        if not meteor.destroyed then
            self:checkProtectedZone(meteor)
        end

        -- Remove destroyed meteors
        if meteor.destroyed then
            table.remove(self.meteors, i)
            self.meteorsDestroyed = self.meteorsDestroyed + 1
            self.score = self.score + 10  -- Points for destroying meteor
        end
    end

    -- Update railgun
    self.railgun:update(dt)

    -- Handle railgun firing input
    if self.input:isPressed("space") and self.ship then
        local x, y = self.ship:getPosition()
        local angle = self.ship:getAngle()
        self.railgun:fire(self.physics:getWorld(), x, y, angle, self.meteors)
    end

    -- Meteor spawning
    self:updateSpawning(dt)

    -- Handle deferred actions (after physics update)
    if self.deferredRespawn then
        self.deferredRespawn = false
        self:respawnShip()
    end

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
    -- Spawn meteor in ring outside screen
    local spawnRadius = Settings.spawning.spawnRadius
    local angle = math.random() * math.pi * 2

    -- Spawn position on ring
    local spawnX = Settings.screen.centerX + math.cos(angle) * spawnRadius
    local spawnY = Settings.screen.centerY + math.sin(angle) * spawnRadius

    -- Velocity towards center with some randomness
    local targetAngle = angle + math.pi + (math.random() - 0.5) * 0.8  -- Add variation
    local speed = math.random() * (Settings.spawning.maxVelocity - Settings.spawning.minVelocity) + Settings.spawning.minVelocity

    local vx = math.cos(targetAngle) * speed
    local vy = math.sin(targetAngle) * speed

    -- Get random meteor type
    local meteorType = MeteorData.getRandom()

    -- Create meteor
    local meteor = Meteor.new(
        self.physics:getWorld(),
        meteorType,
        spawnX, spawnY,
        vx, vy
    )

    table.insert(self.meteors, meteor)

    print("Spawned meteor: " .. meteorType.id .. " (count: " .. #self.meteors .. ")")
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
    self:drawRailgunBeams()
end

function GameState:drawRailgunBeams()
    local DrawSDF = require("src.render.draw_sdf")
    local beamColor = Settings.visual.colors.railgun

    for _, beam in ipairs(self.railgun:getBeams()) do
        -- Draw beam with fade out
        DrawSDF.drawLineSDF(
            beam.startX, beam.startY,
            beam.endX, beam.endY,
            Settings.railgun.beamWidth,
            beamColor,
            Settings.railgun.beamGlow,
            beam.alpha
        )

        -- Draw impact flashes at hit points
        for _, hit in ipairs(beam.hits) do
            local flashRadius = 10 * beam.alpha
            DrawSDF.drawCircleSDF(
                hit.hitX, hit.hitY,
                flashRadius,
                beamColor,
                8,
                beam.alpha * 0.8
            )
        end
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

function GameState:checkProtectedZone(meteor)
    -- Check if meteor is inside protected zone
    local mx, my = meteor:getPosition()
    local cx = Settings.screen.centerX
    local cy = Settings.screen.centerY

    local distance = math.sqrt((mx - cx)^2 + (my - cy)^2)

    -- Check if meteor crossed into protected zone
    if distance < self.protectedZoneRadius then
        -- Penalty based on settings
        if Settings.protectedZone.penaltyType == "instant" then
            -- Instant game over
            print("Meteor breached protected zone! Game Over!")
            self:gameOver()
        else
            -- Lose lives
            self:loseLife()
        end

        -- Destroy the meteor that crossed
        meteor:destroy()
    end
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

    -- Initialize ship at center of screen
    if self.ship then
        self.ship:destroy()
    end
    self.ship = Ship.new(
        self.physics:getWorld(),
        Settings.screen.centerX,
        Settings.screen.centerY
    )

    print("Ship initialized")
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

    if self.lives > 0 then
        -- Mark for respawn (deferred to avoid Box2D locking)
        self.deferredRespawn = true
    else
        -- Game over
        self:gameOver()
    end
end

function GameState:respawnShip()
    if self.ship then
        self.ship:destroy()
    end

    -- Respawn at center with brief invulnerability would be nice
    -- For MVP, just respawn at center
    self.ship = Ship.new(
        self.physics:getWorld(),
        Settings.screen.centerX,
        Settings.screen.centerY
    )

    print("Ship respawned!")
end

return GameState
