--[[
    SDF Rendering System
    Core functions for rendering Signed Distance Field graphics

    All graphics in this game are generated mathematically from SDF data.
    No bitmaps, textures, or sprites - pure procedural rendering.

    Key functions:
    - drawCircleSDF: Draw SDF circle with glow
    - drawCompositeSDF: Draw multiple SDF primitives as one form
    - drawLineSDF: Draw line with glow (for railgun beam)
]]

local DrawSDF = {}

--[[
    Draw a single SDF circle with glow effect
    @param x, y - Center position
    @param radius - Circle radius
    @param color - RGB table {r, g, b}
    @param glowSize - Glow radius (optional, default 5)
    @param alpha - Opacity (optional, default 1.0)
]]
function DrawSDF.drawCircleSDF(x, y, radius, color, glowSize, alpha)
    glowSize = glowSize or 5
    alpha = alpha or 1.0

    local r, g, b = color[1], color[2], color[3]

    -- Draw glow layers (outer to inner)
    local glowLayers = 3
    for i = glowLayers, 1, -1 do
        local layerRadius = radius + (glowSize * i / glowLayers)
        local layerAlpha = (alpha * 0.2) / i

        love.graphics.setColor(r, g, b, layerAlpha)
        love.graphics.circle("fill", x, y, layerRadius)
    end

    -- Draw core circle
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.circle("fill", x, y, radius)

    -- Draw bright outline
    love.graphics.setColor(r * 1.2, g * 1.2, b * 1.2, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, radius)
end

--[[
    Draw composite SDF shape from primitives
    Used for meteor rendering from data definitions

    @param x, y - Base position
    @param primitives - List of primitive shapes from meteor definition
    @param color - RGB table
    @param glowSize - Glow radius
    @param rotation - Rotation angle in radians (optional)
]]
function DrawSDF.drawCompositeSDF(x, y, primitives, color, glowSize, rotation)
    rotation = rotation or 0

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation)

    -- Draw each primitive
    for _, primitive in ipairs(primitives) do
        if primitive.shape == "circle" then
            local px = primitive.offset.x
            local py = primitive.offset.y
            local pr = primitive.r

            DrawSDF.drawCircleSDF(px, py, pr, color, glowSize * 0.5)
        end
        -- Future: add support for ellipses, rectangles, etc.
    end

    love.graphics.pop()
end

--[[
    Draw line with SDF glow (for railgun beam)
    @param x1, y1 - Start position
    @param x2, y2 - End position
    @param thickness - Line thickness
    @param color - RGB table
    @param glowSize - Glow size
    @param alpha - Opacity
]]
function DrawSDF.drawLineSDF(x1, y1, x2, y2, thickness, color, glowSize, alpha)
    glowSize = glowSize or 5
    alpha = alpha or 1.0

    local r, g, b = color[1], color[2], color[3]

    -- Draw glow layers
    local glowLayers = 3
    for i = glowLayers, 1, -1 do
        local layerThickness = thickness + (glowSize * i / glowLayers)
        local layerAlpha = (alpha * 0.3) / i

        love.graphics.setColor(r, g, b, layerAlpha)
        love.graphics.setLineWidth(layerThickness)
        love.graphics.line(x1, y1, x2, y2)
    end

    -- Draw core line
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.setLineWidth(thickness)
    love.graphics.line(x1, y1, x2, y2)

    -- Draw bright core
    love.graphics.setColor(r * 1.5, g * 1.5, b * 1.5, alpha * 0.8)
    love.graphics.setLineWidth(thickness * 0.5)
    love.graphics.line(x1, y1, x2, y2)
end

--[[
    Draw polygon with SDF glow (for ship)
    @param vertices - Table of {x, y} positions
    @param color - RGB table
    @param glowSize - Glow size
    @param filled - Whether to fill polygon (default true)
]]
function DrawSDF.drawPolygonSDF(vertices, color, glowSize, filled)
    glowSize = glowSize or 5
    filled = filled == nil and true or filled

    local r, g, b = color[1], color[2], color[3]

    -- Convert vertices to flat array for love.graphics
    local flatVertices = {}
    for _, v in ipairs(vertices) do
        table.insert(flatVertices, v.x)
        table.insert(flatVertices, v.y)
    end

    if filled then
        -- Draw filled polygon with glow
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.polygon("fill", flatVertices)
    end

    -- Draw outline with glow
    local glowLayers = 2
    for i = glowLayers, 1, -1 do
        local layerWidth = 2 + (glowSize * i / glowLayers)
        local layerAlpha = 0.3 / i

        love.graphics.setColor(r, g, b, layerAlpha)
        love.graphics.setLineWidth(layerWidth)
        love.graphics.polygon("line", flatVertices)
    end

    -- Draw bright outline
    love.graphics.setColor(r * 1.3, g * 1.3, b * 1.3, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", flatVertices)
end

--[[
    Draw text with subtle glow effect
    @param text - Text string
    @param x, y - Position
    @param color - RGB table
    @param align - Alignment (left, center, right)
]]
function DrawSDF.drawTextSDF(text, x, y, color, align)
    align = align or "left"
    local r, g, b = color[1], color[2], color[3]

    -- Draw glow
    love.graphics.setColor(r, g, b, 0.3)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(text, x + dx, y + dy)
            end
        end
    end

    -- Draw text
    love.graphics.setColor(r, g, b, 1.0)
    love.graphics.print(text, x, y)
end

return DrawSDF
