--[[
    Background Rendering System
    Animated solar system with parallax effect

    Features:
    - Central sun with multi-layer glow
    - Orbiting planets at different speeds
    - Parallax movement based on ship position (future)
]]

local DrawSDF = require("src.render.draw_sdf")
local Settings = require("src.data.settings")

local Background = {}
Background.__index = Background

function Background.new()
    local self = setmetatable({}, Background)

    -- Sun properties
    self.sun = {
        x = Settings.screen.centerX,
        y = Settings.screen.centerY,
        radius = Settings.background.sunRadius,
        glow = Settings.background.sunGlow,
        color = {1.0, 0.9, 0.3}
    }

    -- Planets
    self.planets = {}
    for i, planetData in ipairs(Settings.background.planets) do
        table.insert(self.planets, {
            radius = planetData.radius,
            orbitRadius = planetData.orbitRadius,
            orbitSpeed = planetData.orbitSpeed,
            angle = math.random() * math.pi * 2,  -- Random starting angle
            color = planetData.color
        })
    end

    -- Parallax offset
    self.parallaxX = 0
    self.parallaxY = 0

    print("Background system initialized with " .. #self.planets .. " planets")

    return self
end

function Background:update(dt)
    -- Update planet orbits
    for _, planet in ipairs(self.planets) do
        planet.angle = planet.angle + planet.orbitSpeed * dt
    end

    -- TODO: Update parallax based on ship position
end

function Background:draw()
    -- Draw sun
    local sun = self.sun
    DrawSDF.drawCircleSDF(
        sun.x + self.parallaxX * 0.2,
        sun.y + self.parallaxY * 0.2,
        sun.radius,
        sun.color,
        sun.glow,
        0.8
    )

    -- Draw planets
    for _, planet in ipairs(self.planets) do
        local px = self.sun.x + math.cos(planet.angle) * planet.orbitRadius
        local py = self.sun.y + math.sin(planet.angle) * planet.orbitRadius

        -- Apply parallax
        px = px + self.parallaxX * 0.5
        py = py + self.parallaxY * 0.5

        DrawSDF.drawCircleSDF(
            px, py,
            planet.radius,
            planet.color,
            4,  -- glow size
            0.7
        )
    end
end

function Background:setParallax(x, y)
    self.parallaxX = x * Settings.background.parallaxFactor
    self.parallaxY = y * Settings.background.parallaxFactor
end

return Background
