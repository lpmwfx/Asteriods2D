--[[
    Railgun Weapon System
    Instant-hit raycast weapon that penetrates through objects

    Features:
    - world:rayCast() for collision detection
    - Penetrates through all objects hit
    - Cooldown timer between shots
    - Damage calculation and application to meteors
    - Visual beam effect coordination
]]

local Settings = require("src.data.settings")

local Railgun = {}
Railgun.__index = Railgun

function Railgun.new()
    local self = setmetatable({}, Railgun)

    self.cooldown = 0
    self.maxCooldown = Settings.railgun.cooldown
    self.range = Settings.railgun.range
    self.damage = Settings.railgun.damage

    -- Beam visual state (for rendering)
    self.beams = {}  -- Active beam effects

    return self
end

function Railgun:update(dt)
    -- Update cooldown
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
        if self.cooldown < 0 then
            self.cooldown = 0
        end
    end

    -- Update active beams (visual effects)
    for i = #self.beams, 1, -1 do
        local beam = self.beams[i]
        beam.timeLeft = beam.timeLeft - dt

        -- Fade out beam
        beam.alpha = beam.timeLeft / Settings.railgun.beamDuration

        if beam.timeLeft <= 0 then
            table.remove(self.beams, i)
        end
    end
end

function Railgun:canFire()
    return self.cooldown <= 0
end

function Railgun:getCooldownPercent()
    return self.cooldown / self.maxCooldown
end

function Railgun:fire(world, x, y, angle, meteors)
    if not self:canFire() then
        return false
    end

    -- Reset cooldown
    self.cooldown = self.maxCooldown

    -- Calculate raycast end point
    local endX = x + math.sin(angle) * self.range
    local endY = y - math.cos(angle) * self.range

    -- Track hits
    local hits = {}
    local newFragments = {}

    -- Raycast through the world
    world:rayCast(x, y, endX, endY, function(fixture, hitX, hitY, xn, yn, fraction)
        local userData = fixture:getUserData()

        if userData and userData.type == "meteor" then
            local meteor = userData.entity

            -- Record hit
            table.insert(hits, {
                meteor = meteor,
                hitX = hitX,
                hitY = hitY,
                normalX = xn,
                normalY = yn
            })
        end

        -- Return -1 to continue through all objects (penetration)
        return -1
    end)

    -- Apply damage to all hit meteors
    for _, hit in ipairs(hits) do
        hit.meteor:applyDamage(self.damage, hit.hitX, hit.hitY, hit.normalX, hit.normalY)

        -- Check if meteor fragmented
        if hit.meteor.destroyed then
            -- Meteor was destroyed, it may have created fragments
            -- Fragments are already added to world by meteor:fragment()
        end
    end

    -- Create visual beam effect
    local beamEndX, beamEndY = endX, endY

    -- If we hit something, beam ends at the last hit
    if #hits > 0 then
        local lastHit = hits[#hits]
        beamEndX = lastHit.hitX
        beamEndY = lastHit.hitY
    end

    table.insert(self.beams, {
        startX = x,
        startY = y,
        endX = beamEndX,
        endY = beamEndY,
        timeLeft = Settings.railgun.beamDuration,
        alpha = 1.0,
        hits = hits
    })

    print("Railgun fired! Hits: " .. #hits)

    return true
end

function Railgun:draw()
    -- Beams are drawn by the rendering system using self:getBeams()
end

function Railgun:getBeams()
    return self.beams
end

return Railgun
