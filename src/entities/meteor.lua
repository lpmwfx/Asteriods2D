--[[
    Meteor Entity
    SDF-based meteor with Box2D physics

    Features:
    - Loads SDF definition from data/sdf_meteors.lua
    - Box2D circle body for collision (simplified for MVP)
    - Renders from SDF primitives with glow
    - Damage handling for fragmentation
    - Mass based on SDF volume and density
]]

local DrawSDF = require("src.render.draw_sdf")
local Settings = require("src.data.settings")
local MeteorData = require("src.data.sdf_meteors")

local Meteor = {}
Meteor.__index = Meteor

function Meteor.new(world, meteorType, x, y, vx, vy)
    local self = setmetatable({}, Meteor)

    self.world = world
    self.destroyed = false

    -- Load SDF definition
    if type(meteorType) == "string" then
        self.sdfData = MeteorData[meteorType]
    else
        self.sdfData = meteorType  -- Already a table
    end

    if not self.sdfData then
        error("Meteor type not found: " .. tostring(meteorType))
    end

    self.baseRadius = self.sdfData.baseRadius
    self.primitives = self.sdfData.primitives
    self.density = self.sdfData.density
    self.fractureThreshold = self.sdfData.fracture_threshold
    self.color = self.sdfData.color
    self.glowSize = self.sdfData.glowSize

    -- Damage accumulation
    self.damageAccumulated = 0

    -- Create Box2D body
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.body:setLinearVelocity(vx or 0, vy or 0)

    -- Set random angular velocity
    local angularVel = (math.random() - 0.5) * Settings.spawning.angularVelocity
    self.body:setAngularVelocity(angularVel)

    -- Calculate mass from volume and density
    -- Simple approximation: mass = π * r² * density
    local area = math.pi * self.baseRadius * self.baseRadius
    local mass = area * self.density * 0.01  -- Scale down for reasonable physics
    self.body:setMass(mass)

    -- Create circular fixture (simplified collider)
    local shape = love.physics.newCircleShape(self.baseRadius)
    self.fixture = love.physics.newFixture(self.body, shape, 1)
    self.fixture:setUserData({
        type = "meteor",
        entity = self
    })

    -- Restitution (bounciness) for ricochet
    self.fixture:setRestitution(0.8)

    print("Meteor created: " .. self.sdfData.id .. " at " .. x .. ", " .. y)

    return self
end

function Meteor:update(dt)
    if self.destroyed then return end

    -- Screen wrapping (optional - meteors could also just fly off screen)
    -- For now, let them fly off and be cleaned up by spawning system
end

function Meteor:draw()
    if self.destroyed then return end

    local x, y = self.body:getPosition()
    local angle = self.body:getAngle()

    -- Draw meteor using composite SDF
    DrawSDF.drawCompositeSDF(
        x, y,
        self.primitives,
        self.color,
        self.glowSize,
        angle
    )

    -- Debug: draw collision circle
    if Settings.debug.showPhysicsBodies then
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.circle("line", x, y, self.baseRadius)
    end
end

function Meteor:applyDamage(power, hitX, hitY, normalX, normalY)
    if self.destroyed then return end

    self.damageAccumulated = self.damageAccumulated + power

    print("Meteor " .. self.sdfData.id .. " took " .. power .. " damage (total: " .. self.damageAccumulated .. ")")

    -- Check if should fragment
    if self.damageAccumulated >= self.fractureThreshold then
        self:fragment(hitX, hitY, normalX, normalY)
    end
end

function Meteor:fragment(hitX, hitY, normalX, normalY)
    if self.destroyed then return end

    -- Don't fragment if too small
    if self.baseRadius < Settings.fragmentation.minFragmentSize then
        self:destroy()
        return
    end

    print("Fragmenting meteor: " .. self.sdfData.id)

    local x, y = self.body:getPosition()
    local vx, vy = self.body:getLinearVelocity()

    -- Create fragments
    local fragmentCount = Settings.fragmentation.fragmentCount
    local fragments = {}

    for i = 1, fragmentCount do
        -- Scale down fragment
        local scale = math.random() * (Settings.fragmentation.scaleMax - Settings.fragmentation.scaleMin) + Settings.fragmentation.scaleMin

        -- Create scaled SDF data for fragment
        local fragmentSDF = self:createScaledSDF(scale)

        -- Random angle for fragment velocity
        local angle = (math.pi * 2 / fragmentCount) * i + (math.random() - 0.5) * 0.5
        local speed = math.sqrt(vx*vx + vy*vy) + Settings.fragmentation.velocityBoost

        local fragVX = math.cos(angle) * speed
        local fragVY = math.sin(angle) * speed

        -- Spawn offset so fragments don't overlap
        local offsetDist = self.baseRadius * 0.5
        local fragX = x + math.cos(angle) * offsetDist
        local fragY = y + math.sin(angle) * offsetDist

        -- Create fragment meteor
        local fragment = Meteor.new(self.world, fragmentSDF, fragX, fragY, fragVX, fragVY)
        table.insert(fragments, fragment)
    end

    -- Destroy original meteor
    self:destroy()

    return fragments
end

function Meteor:createScaledSDF(scale)
    -- Create a scaled copy of the SDF data
    local scaledSDF = {
        id = self.sdfData.id .. "_fragment",
        type = "sdf_meteor",
        baseRadius = self.baseRadius * scale,
        primitives = {},
        density = self.sdfData.density,
        fracture_threshold = self.sdfData.fracture_threshold * scale,
        color = self.sdfData.color,
        glowSize = self.sdfData.glowSize
    }

    -- Scale all primitives
    for _, prim in ipairs(self.primitives) do
        local scaledPrim = {
            shape = prim.shape,
            r = prim.r * scale,
            offset = {
                x = prim.offset.x * scale,
                y = prim.offset.y * scale
            }
        }
        table.insert(scaledSDF.primitives, scaledPrim)
    end

    return scaledSDF
end

function Meteor:getPosition()
    if self.destroyed then return 0, 0 end
    return self.body:getPosition()
end

function Meteor:getRadius()
    return self.baseRadius
end

function Meteor:destroy()
    if self.destroyed then return end

    self.destroyed = true

    if self.fixture then
        self.fixture:destroy()
        self.fixture = nil
    end

    if self.body then
        self.body:destroy()
        self.body = nil
    end

    print("Meteor destroyed: " .. self.sdfData.id)
end

return Meteor
