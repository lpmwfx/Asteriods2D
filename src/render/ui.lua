--[[
    UI System
    Heads-Up Display and game information overlay

    Displays:
    - Score
    - Lives/Shields
    - Meteor count
    - Railgun cooldown indicator
    - FPS (debug)
]]

local DrawSDF = require("src.render.draw_sdf")
local Settings = require("src.data.settings")

local UI = {}
UI.__index = UI

function UI.new()
    local self = setmetatable({}, UI)

    self.font = love.graphics.getFont()
    self.margin = Settings.ui.margin

    -- UI state
    self.score = 0
    self.lives = 3
    self.meteorCount = 0
    self.railgunCooldown = 0
    self.maxCooldown = Settings.railgun.cooldown

    return self
end

function UI:update(dt)
    -- UI updates if needed
end

function UI:draw()
    -- Save previous color
    local r, g, b, a = love.graphics.getColor()

    -- Draw score (top center)
    love.graphics.setColor(1, 1, 1, Settings.ui.hudAlpha)
    local scoreText = "SCORE: " .. self.score
    local scoreWidth = self.font:getWidth(scoreText)
    love.graphics.print(scoreText, Settings.screen.centerX - scoreWidth/2, self.margin)

    -- Draw lives (top left)
    local livesText = "LIVES: " .. self.lives
    love.graphics.print(livesText, self.margin, self.margin)

    -- Draw meteor count (top right)
    if Settings.debug.showMeteorCount then
        local meteorText = "METEORS: " .. self.meteorCount
        local meteorWidth = self.font:getWidth(meteorText)
        love.graphics.print(meteorText, Settings.screen.width - meteorWidth - self.margin, self.margin)
    end

    -- Draw FPS (bottom right)
    if Settings.debug.showFPS then
        local fps = love.timer.getFPS()
        local fpsText = "FPS: " .. fps
        local fpsWidth = self.font:getWidth(fpsText)
        love.graphics.print(fpsText, Settings.screen.width - fpsWidth - self.margin, Settings.screen.height - 30)
    end

    -- Draw railgun cooldown indicator (bottom left)
    self:drawCooldownBar()

    -- Restore color
    love.graphics.setColor(r, g, b, a)
end

function UI:drawCooldownBar()
    local barWidth = 150
    local barHeight = 15
    local x = self.margin
    local y = Settings.screen.height - self.margin - barHeight

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight)

    -- Cooldown progress
    local progress = 1.0 - (self.railgunCooldown / self.maxCooldown)
    local fillWidth = barWidth * progress

    if progress >= 1.0 then
        love.graphics.setColor(0.3, 1.0, 0.9, 0.9)  -- Ready color
    else
        love.graphics.setColor(0.9, 0.5, 0.2, 0.7)  -- Cooldown color
    end
    love.graphics.rectangle("fill", x, y, fillWidth, barHeight)

    -- Border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, barWidth, barHeight)

    -- Label
    love.graphics.print("RAILGUN", x, y - 20)
end

function UI:setScore(score)
    self.score = score
end

function UI:setLives(lives)
    self.lives = lives
end

function UI:setMeteorCount(count)
    self.meteorCount = count
end

function UI:setRailgunCooldown(cooldown)
    self.railgunCooldown = cooldown
end

return UI
