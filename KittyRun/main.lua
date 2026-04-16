-- main.lua
-- Kitty Run - Main entry point

gameState = "menu"  -- "menu", "settings", "game", "paused"

-- Splash screen variables
splash = {}
splash.image = nil
splash.timer = 0
splash.active = true
splash.duration = 3
splash.randomProgress = 0
splash.waitFrames = 0

function love.load()
    love.graphics.setDefaultFilter("linear", "nearest", 0)
    love.audio.setVolume(1)
    love.window.setTitle("Kitty Run")
    love.window.setMode(800, 600)
    
    -- Load splash image
    splash.image = love.graphics.newImage("assets/images/splash.png")
    
    -- Load modules
    menu = require("menu")
    game = require("game")
    settings = require("settings")
    
    -- Initialize modules
    menu.load()
    game.load()
    settings.load()
    
    -- Start with splash screen active
    splash.active = true
    splash.timer = 0
    splash.randomProgress = 0
    splash.waitFrames = 0
end

function love.update(dt)
    if dt > 0.033 then dt = 0.033 end
    
    -- Splash screen update
    if splash.active then
        splash.timer = splash.timer + dt
        if splash.randomProgress >= 1 and splash.timer >= 2 then
            splash.active = false
            menu.activate()
        end
        return
    end
    
    if gameState == "menu" then
        menu.update(dt)
    elseif gameState == "settings" then
        settings.update(dt)
    elseif gameState == "game" then
        game.update(dt)
    elseif gameState == "paused" then
        game.updatePaused(dt)
    end
end

function love.draw()
    -- Splash screen draw
    if splash.active then
        local w = splash.image:getWidth()
        local h = splash.image:getHeight()
        love.graphics.draw(splash.image, 400 - w/2, 300 - h/2)
        
        -- Loading bar (random pauses)
        if splash.waitFrames <= 0 then
            splash.randomProgress = splash.randomProgress + math.random(1, 5) / 100
            if splash.randomProgress > 1 then
                splash.randomProgress = 1
            end
            splash.waitFrames = math.random(0, 30)
        else
            splash.waitFrames = splash.waitFrames - 1
        end
        
        local progress = splash.randomProgress
        
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 200, 450, 400, 20)
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.rectangle("fill", 200, 450, 400 * progress, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(14)
        local percent = math.floor(progress * 100)
        local percentText = percent .. "%"
        local textWidth = love.graphics.getFont():getWidth(percentText)
        love.graphics.print(percentText, 400 - textWidth/2, 455)
        return
    end
    
    if gameState == "menu" then
        menu.draw()
    elseif gameState == "settings" then
        settings.draw()
    elseif gameState == "game" then
        game.draw()
    elseif gameState == "paused" then
        game.draw()
        game.drawPauseOverlay()
    end
end

function love.keypressed(key)
    if splash.active then
        if key == "space" or key == "return" then
            splash.active = false
            menu.activate()
        end
        return
    end
    
    if gameState == "menu" then
        menu.keypressed(key)
    elseif gameState == "settings" then
        settings.keypressed(key)
    elseif gameState == "game" then
        game.keypressed(key)
    elseif gameState == "paused" then
        if key == "escape" then
            game.resume()
        end
    end
end

function love.mousepressed(x, y, button)
    if splash.active then return end
    
    if gameState == "menu" then
        menu.mousepressed(x, y, button)
    elseif gameState == "settings" then
        settings.mousepressed(x, y, button)
    elseif gameState == "game" then
        game.mousepressed(x, y, button)
    end
end

function love.quit()
    if settings and settings.save then
        settings.save()
    end
end