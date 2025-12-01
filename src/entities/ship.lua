--[[
    Player Ship Entity
    Triangle-shaped ship with rotation and thrust controls

    Features:
    - Box2D polygon body for physics
    - Rotation controls (left/right arrow keys)
    - Forward thrust (up arrow key)
    - SDF rendering with glow effect
    - Physics properties: mass, friction, angular damping

    Controls handled via Input system
]]

local DrawSDF = require("src.render.draw_sdf")
local Settings = require("src.data.settings")

local Ship = {}
Ship.__index = Ship

function Ship.new(world, x, y)
    local self = setmetatable({}, Ship)

    self.world = world
    self.alive = true

    -- Ship dimensions (triangle pointing up initially)
    self.size = Settings.ship.size
    self.color = Settings.visual.colors.ship
    self.glowSize = Settings.ship.glowSize

    -- Create Box2D body
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.body:setLinearDamping(Settings.ship.drag)
    self.body:setAngularDamping(Settings.ship.angularDrag)
    self.body:setMass(Settings.ship.mass)

    -- Create triangle shape for collision
    -- Triangle points: front tip, back left, back right
    local halfSize = self.size / 2
    local shape = love.physics.newPolygonShape(
        0, -self.size,           -- Front tip
        -halfSize, halfSize,     -- Back left
        halfSize, halfSize       -- Back right
    )

    -- Create fixture
    self.fixture = love.physics.newFixture(self.body, shape, 1)
    self.fixture:setUserData({
        type = "ship",
        entity = self
    })

    -- Physics properties
    self.thrust = Settings.ship.thrust
    self.rotationSpeed = Settings.ship.rotationSpeed
    self.maxSpeed = Settings.ship.maxSpeed

    -- Visual state
    self.thrustParticles = {}
    self.showThrust = false

    print("Ship created at position: " .. x .. ", " .. y)

    return self
end

function Ship:update(dt, input)
    if not self.alive then return end

    -- Rotation control
    if input:isDown("left") then
        self.body:setAngularVelocity(-self.rotationSpeed)
    elseif input:isDown("right") then
        self.body:setAngularVelocity(self.rotationSpeed)
    else
        self.body:setAngularVelocity(0)
    end

    -- Thrust control
    self.showThrust = false
    if input:isDown("up") then
        local angle = self.body:getAngle()
        local fx = math.sin(angle) * self.thrust
        local fy = -math.cos(angle) * self.thrust

        self.body:applyForce(fx, fy)
        self.showThrust = true
    end

    -- Limit max speed
    local vx, vy = self.body:getLinearVelocity()
    local speed = math.sqrt(vx*vx + vy*vy)
    if speed > self.maxSpeed then
        local scale = self.maxSpeed / speed
        self.body:setLinearVelocity(vx * scale, vy * scale)
    end

    -- Screen wrapping
    self:wrapPosition()
end

function Ship:wrapPosition()
    local x, y = self.body:getPosition()
    local screenW = Settings.screen.width
    local screenH = Settings.screen.height
    local margin = 50

    local wrapped = false

    if x < -margin then
        x = screenW + margin
        wrapped = true
    elseif x > screenW + margin then
        x = -margin
        wrapped = true
    end

    if y < -margin then
        y = screenH + margin
        wrapped = true
    elseif y > screenH + margin then
        y = -margin
        wrapped = true
    end

    if wrapped then
        self.body:setPosition(x, y)
    end
end

function Ship:draw()
    if not self.alive then return end

    local x, y = self.body:getPosition()
    local angle = self.body:getAngle()

    -- Build triangle vertices in local space
    local halfSize = self.size / 2
    local vertices = {
        {x = 0, y = -self.size},        -- Front tip
        {x = -halfSize, y = halfSize},  -- Back left
        {x = halfSize, y = halfSize}    -- Back right
    }

    -- Transform vertices by ship rotation
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    local transformedVerts = {}

    for _, v in ipairs(vertices) do
        local rotX = v.x * cos_a - v.y * sin_a
        local rotY = v.x * sin_a + v.y * cos_a
        table.insert(transformedVerts, {
            x = x + rotX,
            y = y + rotY
        })
    end

    -- Draw thrust effect if active
    if self.showThrust then
        self:drawThrustEffect(x, y, angle)
    end

    -- Draw ship using SDF polygon
    DrawSDF.drawPolygonSDF(transformedVerts, self.color, self.glowSize, true)
end

function Ship:drawThrustEffect(x, y, angle)
    -- Draw simple thrust flame behind ship
    local thrustLength = 15
    local thrustWidth = 8

    -- Back center of ship
    local backX = x - math.sin(angle) * self.size * 0.5
    local backY = y + math.cos(angle) * self.size * 0.5

    -- Thrust tip (pointing away from ship direction)
    local tipX = backX - math.sin(angle) * thrustLength
    local tipY = backY + math.cos(angle) * thrustLength

    -- Thrust sides
    local sideAngle = angle + math.pi / 2
    local side1X = backX + math.cos(sideAngle) * thrustWidth * 0.5
    local side1Y = backY + math.sin(sideAngle) * thrustWidth * 0.5
    local side2X = backX - math.cos(sideAngle) * thrustWidth * 0.5
    local side2Y = backY - math.sin(sideAngle) * thrustWidth * 0.5

    -- Draw thrust triangle
    local thrustVerts = {
        {x = side1X, y = side1Y},
        {x = tipX, y = tipY},
        {x = side2X, y = side2Y}
    }

    local thrustColor = {1.0, 0.7, 0.2}  -- Orange/yellow flame
    DrawSDF.drawPolygonSDF(thrustVerts, thrustColor, 4, true)
end

function Ship:getPosition()
    return self.body:getPosition()
end

function Ship:getAngle()
    return self.body:getAngle()
end

function Ship:destroy()
    self.alive = false
    if self.fixture then
        self.fixture:destroy()
        self.fixture = nil
    end
    if self.body then
        self.body:destroy()
        self.body = nil
    end
    print("Ship destroyed")
end

function Ship:takeDamage()
    -- Simple damage for MVP - just destroy ship
    self:destroy()
end

return Ship
