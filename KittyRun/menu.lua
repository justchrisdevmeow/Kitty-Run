-- menu.lua
local menu = {}

local buttons = {}
local hoverButton = nil
local bgImage = nil
local catLogo = nil

function menu.load()
    -- Load assets
    bgImage = love.graphics.newImage("assets/images/bg.png")
    catLogo = love.graphics.newImage("assets/images/cat1.png")
    
    buttons = {
        play = { x = 300, y = 350, w = 200, h = 60, text = "Play" },
        settings = { x = 300, y = 430, w = 200, h = 60, text = "Settings" }
    }
end

function menu.activate()
    gameState = "menu"
end

function menu.update(dt)
    -- Update mouse position for hover
    local mx, my = love.mouse.getPosition()
    hoverButton = nil
    for id, btn in pairs(buttons) do
        if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            hoverButton = id
            break
        end
    end
end

function menu.draw()
    -- Background
    if bgImage then
        love.graphics.draw(bgImage, (800 - bgImage:getWidth())/2, (600 - bgImage:getHeight())/2)
    else
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
    end
    
    -- Dark overlay for readability
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    
    -- Cat logo
    if catLogo then
        love.graphics.setColor(1, 1, 1)
        local logoW = catLogo:getWidth() * 2
        local logoH = catLogo:getHeight() * 2
        love.graphics.draw(catLogo, 400 - logoW/2, 100, 0, 2, 2)
    end
    
    -- Title text
    love.graphics.setColor(1, 0.8, 0.3)
    love.graphics.setFont(love.graphics.newFont(48))
    local title = "Kitty Run"
    local tw = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, 400 - tw/2, 200)
    
    -- Subtitle
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local sub = "A purr-fect endless runner"
    local sw = love.graphics.getFont():getWidth(sub)
    love.graphics.print(sub, 400 - sw/2, 260)
    
    -- Draw buttons
    for id, btn in pairs(buttons) do
        -- Button background
        if hoverButton == id then
            love.graphics.setColor(0.4, 0.6, 0.8)
        else
            love.graphics.setColor(0.2, 0.3, 0.5)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10)
        
        -- Button border
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10)
        
        -- Button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(24))
        local tw = love.graphics.getFont():getWidth(btn.text)
        love.graphics.print(btn.text, btn.x + btn.w/2 - tw/2, btn.y + btn.h/2 - 12)
    end
    
    -- Footer
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(love.graphics.newFont(12))
    local made = "Made by justdev-chris"
    local mw = love.graphics.getFont():getWidth(made)
    love.graphics.print(made, 400 - mw/2, 570)
end

function menu.mousepressed(x, y, button)
    if button == 1 then
        for id, btn in pairs(buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                if id == "play" then
                    game.start()
                elseif id == "settings" then
                    settings.activate()
                end
            end
        end
    end
end

function menu.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return menu