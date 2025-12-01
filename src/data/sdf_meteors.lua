--[[
    SDF Meteor Definitions
    Data-driven meteor shape definitions using SDF primitives

    Each meteor is composed of primitive shapes (circles, ellipses)
    that are combined using CSG operations

    Structure:
    {
        id = unique identifier
        type = "sdf_meteor"
        primitives = list of shapes
        density = mass per unit area
        fracture_threshold = damage needed to fragment
    }
]]

local Meteors = {
    -- Small meteor variants
    small_01 = {
        id = "small_01",
        type = "sdf_meteor",
        baseRadius = 25,
        primitives = {
            { shape = "circle", r = 25, offset = {x = 0, y = 0} },
            { shape = "circle", r = 12, offset = {x = 8, y = -6} },
            { shape = "circle", r = 10, offset = {x = -7, y = 8} }
        },
        density = 1.0,
        fracture_threshold = 50,
        color = {0.9, 0.5, 0.2},
        glowSize = 3
    },

    small_02 = {
        id = "small_02",
        type = "sdf_meteor",
        baseRadius = 20,
        primitives = {
            { shape = "circle", r = 20, offset = {x = 0, y = 0} },
            { shape = "circle", r = 8, offset = {x = 6, y = 5} }
        },
        density = 1.2,
        fracture_threshold = 45,
        color = {0.85, 0.55, 0.25},
        glowSize = 3
    },

    -- Medium meteor variants
    medium_01 = {
        id = "medium_01",
        type = "sdf_meteor",
        baseRadius = 45,
        primitives = {
            { shape = "circle", r = 45, offset = {x = 0, y = 0} },
            { shape = "circle", r = 22, offset = {x = 15, y = -10} },
            { shape = "circle", r = 18, offset = {x = -12, y = 14} },
            { shape = "circle", r = 15, offset = {x = -8, y = -12} }
        },
        density = 1.5,
        fracture_threshold = 100,
        color = {0.95, 0.45, 0.15},
        glowSize = 4
    },

    medium_02 = {
        id = "medium_02",
        type = "sdf_meteor",
        baseRadius = 40,
        primitives = {
            { shape = "circle", r = 40, offset = {x = 0, y = 0} },
            { shape = "circle", r = 20, offset = {x = 12, y = 8} },
            { shape = "circle", r = 16, offset = {x = -10, y = -10} }
        },
        density = 1.3,
        fracture_threshold = 90,
        color = {0.88, 0.52, 0.22},
        glowSize = 4
    },

    -- Large meteor variants
    large_01 = {
        id = "large_01",
        type = "sdf_meteor",
        baseRadius = 70,
        primitives = {
            { shape = "circle", r = 70, offset = {x = 0, y = 0} },
            { shape = "circle", r = 35, offset = {x = 20, y = -15} },
            { shape = "circle", r = 30, offset = {x = -18, y = 20} },
            { shape = "circle", r = 25, offset = {x = 15, y = 18} },
            { shape = "circle", r = 20, offset = {x = -20, y = -15} }
        },
        density = 2.0,
        fracture_threshold = 150,
        color = {1.0, 0.4, 0.1},
        glowSize = 5
    },

    large_02 = {
        id = "large_02",
        type = "sdf_meteor",
        baseRadius = 65,
        primitives = {
            { shape = "circle", r = 65, offset = {x = 0, y = 0} },
            { shape = "circle", r = 32, offset = {x = 18, y = 12} },
            { shape = "circle", r = 28, offset = {x = -15, y = -18} },
            { shape = "circle", r = 22, offset = {x = -12, y = 15} }
        },
        density = 1.8,
        fracture_threshold = 140,
        color = {0.92, 0.48, 0.18},
        glowSize = 5
    }
}

-- Helper function to get random meteor by size category
function Meteors.getRandomBySize(size)
    local options = {}

    if size == "small" then
        table.insert(options, Meteors.small_01)
        table.insert(options, Meteors.small_02)
    elseif size == "medium" then
        table.insert(options, Meteors.medium_01)
        table.insert(options, Meteors.medium_02)
    elseif size == "large" then
        table.insert(options, Meteors.large_01)
        table.insert(options, Meteors.large_02)
    end

    if #options > 0 then
        return options[math.random(#options)]
    end

    return Meteors.small_01  -- Fallback
end

-- Helper function to get random meteor of any size
function Meteors.getRandom()
    local sizes = {"small", "medium", "large"}
    local size = sizes[math.random(#sizes)]
    return Meteors.getRandomBySize(size)
end

return Meteors
