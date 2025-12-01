--[[
    Physics System
    Box2D physics world management for space environment

    Key features:
    - Zero gravity (space simulation)
    - Collision detection and callbacks
    - Body/fixture lifecycle management
]]

local Physics = {}
Physics.__index = Physics

-- Physics constants
local METER_SIZE = 64  -- Pixels per meter (Box2D works in meters)

function Physics.new()
    local self = setmetatable({}, Physics)

    -- Create Box2D world with zero gravity (space!)
    self.world = love.physics.newWorld(0, 0, true)  -- gx=0, gy=0, sleep=true

    -- Set meter scale
    love.physics.setMeter(METER_SIZE)

    -- Collision callbacks storage
    self.collisionCallbacks = {}

    -- Setup collision callbacks
    self.world:setCallbacks(
        function(a, b, contact) self:beginContact(a, b, contact) end,
        function(a, b, contact) self:endContact(a, b, contact) end,
        function(a, b, contact) self:preSolve(a, b, contact) end,
        function(a, b, contact) self:postSolve(a, b, contact) end
    )

    print("Physics system initialized (gravity: 0, meter: " .. METER_SIZE .. "px)")

    return self
end

function Physics:update(dt)
    -- Update physics world
    -- Using smaller timesteps for more stable physics
    self.world:update(dt)
end

function Physics:getWorld()
    return self.world
end

function Physics:getMeterSize()
    return METER_SIZE
end

--[[
    Collision callback registration
    Entities can register custom collision handlers
]]
function Physics:registerCollisionCallback(category, callback)
    self.collisionCallbacks[category] = callback
end

--[[
    Collision callbacks from Box2D
]]
function Physics:beginContact(fixtureA, fixtureB, contact)
    local dataA = fixtureA:getUserData()
    local dataB = fixtureB:getUserData()

    -- Call registered callbacks if they exist
    if dataA and self.collisionCallbacks[dataA.type] then
        self.collisionCallbacks[dataA.type](dataA, dataB, contact)
    end

    if dataB and self.collisionCallbacks[dataB.type] then
        self.collisionCallbacks[dataB.type](dataB, dataA, contact)
    end
end

function Physics:endContact(fixtureA, fixtureB, contact)
    -- Called when two fixtures cease to overlap
end

function Physics:preSolve(fixtureA, fixtureB, contact)
    -- Called before physics resolution
end

function Physics:postSolve(fixtureA, fixtureB, contact, normalImpulse, tangentImpulse)
    -- Called after physics resolution
end

function Physics:destroy()
    if self.world then
        self.world:destroy()
        self.world = nil
    end
end

return Physics
