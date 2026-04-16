-- settings.lua
local settings = {}

local backButton = { x = 300, y = 480, w = 200, h = 50, text = "Back" }
local hoverBack = false

-- Toggles (moved right and down)
local muteToggle = { x = 450, y = 280, w = 60, h = 30, enabled = false }
local hoverMute = false

function settings.load()
    if love.filesystem.getInfo("mute.txt") then
        local content = love.filesystem.read("mute.txt")
        muteToggle.enabled = (content == "true")
    else
        muteToggle.enabled = false
    end
    love.audio.setVolume(muteToggle.enabled and 0 or 1)
end

function settings.activate()
    gameState = "settings"
end

function settings.update(dt)
    local mx, my = love.mouse.getPosition()
    
    hoverBack = (mx >= backButton.x and mx <= backButton.x + backButton.w and
                 my >= backButton.y and my <= backButton.y + backButton.h)
    
    hoverMute = (mx >= muteToggle.x and mx <= muteToggle.x + muteToggle.w and
                 my >= muteToggle.y and my <= muteToggle.y + muteToggle.h)
end

function settings.draw()
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    local title = "Settings"
    local tw = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, 400 - tw/2, 80)
    
    -- Mute toggle section
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Mute Sound", 300, 285)
    
    -- Toggle background
    if muteToggle.enabled then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.5, 0.3, 0.3)
    end
    love.graphics.rectangle("fill", muteToggle.x, muteToggle.y, muteToggle.w, muteToggle.h, 15)
    
    -- Toggle circle
    if muteToggle.enabled then
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", muteToggle.x + muteToggle.w - 15, muteToggle.y + 15, 12)
    else
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.circle("fill", muteToggle.x + 15, muteToggle.y + 15, 12)
    end
    
    -- Controls display
    love.graphics.setColor(0.3, 0.3, 0.5)
    love.graphics.rectangle("fill", 150, 360, 500, 100, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("Controls:", 160, 375)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("SPACE = Jump", 160, 400)
    love.graphics.print("ESC = Pause", 160, 420)
    love.graphics.print("M = Mute", 160, 440)
    
    -- Back button
    if hoverBack then
        love.graphics.setColor(0.4, 0.4, 0.6)
    else
        love.graphics.setColor(0.2, 0.2, 0.4)
    end
    love.graphics.rectangle("fill", backButton.x, backButton.y, backButton.w, backButton.h, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    local bw = love.graphics.getFont():getWidth(backButton.text)
    love.graphics.print(backButton.text, backButton.x + backButton.w/2 - bw/2, backButton.y + backButton.h/2 - 12)
end

function settings.mousepressed(x, y, button)
    if button == 1 then
        if x >= backButton.x and x <= backButton.x + backButton.w and
           y >= backButton.y and y <= backButton.y + backButton.h then
            menu.activate()
            return
        end
        
        if x >= muteToggle.x and x <= muteToggle.x + muteToggle.w and
           y >= muteToggle.y and y <= muteToggle.y + muteToggle.h then
            muteToggle.enabled = not muteToggle.enabled
            love.audio.setVolume(muteToggle.enabled and 0 or 1)
            love.filesystem.write("mute.txt", tostring(muteToggle.enabled))
        end
    end
end

function settings.keypressed(key)
    if key == "escape" then
        menu.activate()
    end
end

function settings.save()
    love.filesystem.write("mute.txt", tostring(muteToggle.enabled))
end

return settings