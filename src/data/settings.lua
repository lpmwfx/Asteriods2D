--[[
    Game Settings and Constants
    All game parameters centralized here (data-driven design)

    No hardcoded values in game logic - everything comes from here
]]

local Settings = {
    -- Screen dimensions (VIRTUAL RESOLUTION - FASE 2)
    -- Game is designed for 1920x1080 and scales to any actual screen size
    screen = {
        width = 1920,
        height = 1080,
        centerX = 960,
        centerY = 540
    },

    -- Physics settings
    physics = {
        meterSize = 64,          -- Pixels per meter for Box2D
        timeStep = 1/60,         -- Fixed timestep for physics
        velocityIterations = 8,
        positionIterations = 3
    },

    -- Ship settings
    ship = {
        mass = 10,
        thrust = 300,            -- Forward thrust force
        rotationSpeed = 3.5,     -- Radians per second
        drag = 0.1,              -- Linear damping (space friction)
        angularDrag = 0.2,       -- Angular damping
        maxSpeed = 400,          -- Maximum velocity
        size = 20,               -- Triangle size in pixels
        glowSize = 5             -- SDF glow radius
    },

    -- Railgun settings
    railgun = {
        cooldown = 1.0,          -- Seconds between shots
        range = 2000,            -- Maximum raycast distance
        damage = 100,            -- Damage per hit
        beamWidth = 3,           -- Beam thickness
        beamGlow = 8,            -- Glow size
        beamDuration = 0.15,     -- Visual beam fade time
        screenShake = 3          -- Screen shake intensity
    },

    -- Meteor spawning
    spawning = {
        spawnRadius = 1400,      -- Distance from center to spawn (scaled for 1920x1080)
        spawnInterval = 2.0,     -- Seconds between spawns
        maxMeteors = 10,         -- Maximum active meteors
        minVelocity = 30,        -- Minimum meteor speed
        maxVelocity = 100,       -- Maximum meteor speed
        angularVelocity = 2.0    -- Rotation speed variation
    },

    -- Protected zone
    protectedZone = {
        radius = 225,            -- Inner zone radius (scaled for 1920x1080)
        penaltyType = "instant", -- "instant" or "lives"
        livesLost = 1            -- Lives lost when meteor crosses
    },

    -- Meteor types (references to sdf_meteors.lua definitions)
    meteorTypes = {
        "small_01",
        "medium_01",
        "large_01"
    },

    -- Fragmentation settings
    fragmentation = {
        minFragmentSize = 15,    -- Stop fragmenting below this radius
        fragmentCount = 3,       -- Number of fragments per break
        scaleMin = 0.5,          -- Minimum fragment scale
        scaleMax = 0.7,          -- Maximum fragment scale
        velocityBoost = 50       -- Additional velocity for fragments
    },

    -- Visual settings
    visual = {
        glowLayers = 3,          -- Number of glow layers for SDF
        glowFalloff = 0.5,       -- Glow intensity falloff
        backgroundColor = {0.02, 0.02, 0.05, 1.0},

        -- Color palettes
        colors = {
            ship = {0.2, 0.8, 1.0},
            meteor = {0.9, 0.5, 0.2},
            railgun = {0.3, 1.0, 0.9},
            protectedZone = {0.3, 0.5, 1.0},
            background = {0.1, 0.05, 0.15}
        }
    },

    -- Background settings (scaled for 1920x1080 virtual resolution)
    background = {
        sunRadius = 120,
        sunGlow = 60,
        planetCount = 3,

        planets = {
            {
                radius = 38,
                orbitRadius = 300,
                orbitSpeed = 0.1,
                color = {0.9, 0.7, 0.3}
            },
            {
                radius = 52,
                orbitRadius = 525,
                orbitSpeed = 0.05,
                color = {0.4, 0.6, 0.9}
            },
            {
                radius = 30,
                orbitRadius = 750,
                orbitSpeed = 0.15,
                color = {0.7, 0.3, 0.5}
            }
        },

        parallaxFactor = 0.1,  -- Ship movement affects background

        -- Perspective settings (20-30 degree view from above)
        perspectiveAngle = 25,  -- Degrees from top-down (0 = top-down, 90 = side view)
        orbitEllipseRatio = 0.4,  -- How much orbits are compressed (0.5 = 45 deg perspective)
        depthScaleFactor = 0.3  -- Size reduction for objects further back
    },

    -- UI settings
    ui = {
        fontSize = 20,
        margin = 20,
        hudAlpha = 0.9
    },

    -- Debug settings
    debug = {
        showPhysicsBodies = false,
        showFPS = true,
        showMeteorCount = true
    }
}

return Settings
