function love.load()
    love.graphics.setDefaultFilter("linear", "nearest", 0)
    love.audio.setVolume(1)
    love.window.setTitle("Kitty Run")
    
    -- SPLASH SCREEN
    splash = {}
    splash.image = love.graphics.newImage("assets/images/splash.png")
    splash.timer = 0
    splash.active = true
    splash.duration = 3
    
    function createCollisionMap(imgPath)
        local imgData = love.image.newImageData(imgPath)
        local width = imgData:getWidth()
        local height = imgData:getHeight()
        
        local collisionMap = {}
        for y = 0, height - 1 do
            collisionMap[y] = {}
            for x = 0, width - 1 do
                local r, g, b, a = imgData:getPixel(x, y)
                local isWhite = (r > 0.95 and g > 0.95 and b > 0.95)
                collisionMap[y][x] = (a > 0 and not isWhite)
            end
        end
        
        for y = 0, height - 1 do
            for x = 0, width - 1 do
                local r, g, b, a = imgData:getPixel(x, y)
                if r > 0.9 and g > 0.9 and b > 0.9 then
                    imgData:setPixel(x, y, r, g, b, 0)
                end
            end
        end
        
        return {
            image = love.graphics.newImage(imgData),
            width = width,
            height = height,
            collision = collisionMap
        }
    end
    
    bg = love.graphics.newImage("assets/images/bg.png")
    bg_width = bg:getWidth()
    bg_height = bg:getHeight()
    
    meowSounds = {
        love.audio.newSource("assets/sounds/meow1.mp3", "static"),
        love.audio.newSource("assets/sounds/meow2.mp3", "static"),
        love.audio.newSource("assets/sounds/meow3.mp3", "static")
    }
    jumpSound = love.audio.newSource("assets/sounds/jump.mp3", "static")
    
    deathSounds = {
        love.audio.newSource("assets/sounds/death1.mp3", "static"),
        love.audio.newSource("assets/sounds/death2.mp3", "static"),
        love.audio.newSource("assets/sounds/death3.mp3", "static"),
        love.audio.newSource("assets/sounds/death4.mp3", "static")
    }
    for _, sound in ipairs(deathSounds) do
        sound:setVolume(0.5)
    end
    
    cat_data = {
        createCollisionMap("assets/images/cat1.png"),
        createCollisionMap("assets/images/cat2.png")
    }
    cat_frames = { cat_data[1].image, cat_data[2].image }
    cat_collision = cat_data[1].collision
    cat_width = cat_data[1].width
    cat_height = cat_data[1].height
    
    dog_data = createCollisionMap("assets/images/dog.png")
    puddle_data = createCollisionMap("assets/images/puddle.png")
    pickle_data = createCollisionMap("assets/images/pickle.png")
    cactus_data = createCollisionMap("assets/images/cactus.png")
    
    obstacle_types = {
        { data = dog_data, name = "dog" },
        { data = puddle_data, name = "puddle" },
        { data = pickle_data, name = "pickle" },
        { data = cactus_data, name = "cactus" }
    }
    
    cat_frame = 1
    cat_anim_timer = 0
    
    cat = { x = 100, y = 0, vy = 0, jumping = false, width = cat_width, height = cat_height }
    ground = 550
    score = 0
    lastMeowScore = 0
    gameOver = false
    started = false
    audioEnabled = false
    obstacles = {}
    spawnTimer = 0
    
    love.window.setMode(800, 600)
    
    -- Ensure splash is active on fresh launch
    splash.active = true
    splash.timer = 0
end

function love.update(dt)
    if dt > 0.033 then dt = 0.033 end
    
    -- SPLASH UPDATE
    if splash.active then
        splash.timer = splash.timer + dt
        if splash.timer >= splash.duration then
            splash.active = false
        end
        return
    end
    
    if gameOver then return end
    
    if not started then
        return
    end
    
    cat.vy = cat.vy + 800 * dt
    cat.y = cat.y + cat.vy * dt
    
    if cat.y >= ground - cat.height then
        cat.y = ground - cat.height
        cat.jumping = false
        cat.vy = 0
    end
    
    if cat.y < 0 then
        cat.y = 0
        cat.vy = 0
    end
    
    if love.keyboard.isDown("space") and not cat.jumping then
        if not audioEnabled then
            audioEnabled = true
            local dummy = love.audio.newSource("assets/sounds/meow1.mp3", "static")
            dummy:play()
            dummy:stop()
        end
        cat.vy = -380
        cat.jumping = true
        if audioEnabled then
            jumpSound:stop()
            jumpSound:play()
        end
    end
    
    if not cat.jumping then
        cat_anim_timer = cat_anim_timer + dt
        if cat_anim_timer > 0.1 then
            cat_anim_timer = 0
            cat_frame = cat_frame + 1
            if cat_frame > 2 then cat_frame = 1 end
        end
    end
    
    spawnTimer = spawnTimer + dt
    if spawnTimer > 1.5 then
        spawnTimer = 0
        local t = obstacle_types[math.random(#obstacle_types)]
        local spawnX = math.random(800, 1000)
        
        local y_offset = 0
        if t.name == "pickle" then
            y_offset = -5
        end
        if t.name == "puddle" then
            y_offset = -5
        end
        
        table.insert(obstacles, {
            x = spawnX,
            y = ground - t.data.height + y_offset,
            data = t.data,
            name = t.name
        })
    end
    
    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.x = obs.x - 250 * dt
        if obs.x + obs.data.width < 0 then
            table.remove(obstacles, i)
            score = score + 10
        end
    end
    
    score = score + 30 * dt
    
    local scoreInt = math.floor(score)
    if scoreInt >= lastMeowScore + 500 then
        lastMeowScore = lastMeowScore + 500
        if audioEnabled then
            local idx = math.random(1, #meowSounds)
            meowSounds[idx]:stop()
            meowSounds[idx]:play()
        end
    end
    
    for i, obs in ipairs(obstacles) do
        local y_shrink = 10
        if obs.name == "puddle" then
            y_shrink = 15
        end
        if obs.name == "pickle" then
            y_shrink = 20
        end
        
        local obs_left = obs.x + 10
        local obs_right = obs.x + obs.data.width - 10
        local obs_top = obs.y + y_shrink
        local obs_bottom = obs.y + obs.data.height - y_shrink
        
        if cat.x < obs_right and
           cat.x + cat.width > obs_left and
           cat.y < obs_bottom and
           cat.y + cat.height > obs_top then
            if audioEnabled then
                local idx = math.random(1, #deathSounds)
                deathSounds[idx]:stop()
                deathSounds[idx]:play()
            end
            gameOver = true
            break
        end
    end
end

function love.draw()
    -- SPLASH DRAW
    if splash.active then
        local w = splash.image:getWidth()
        local h = splash.image:getHeight()
        love.graphics.draw(splash.image, 400 - w/2, 300 - h/2)
        return
    end
    
    if bg then
        local bx = (800 - bg_width) / 2
        local by = (600 - bg_height) / 2
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(bg, bx, by)
    else
        love.graphics.setColor(0.53, 0.81, 0.92)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
    end
    
    love.graphics.setColor(0.55, 0.27, 0.07)
    love.graphics.rectangle("fill", 0, ground, 800, 600 - ground)
    love.graphics.setColor(0.34, 0.55, 0.17)
    love.graphics.rectangle("fill", 0, ground - 5, 800, 5)
    
    love.graphics.setColor(1, 1, 1)
    local w = cat_frames[cat_frame]:getWidth()
    local h = cat_frames[cat_frame]:getHeight()
    love.graphics.draw(cat_frames[cat_frame], cat.x + cat.width/2, cat.y + cat.height/2 - 5, 0, 1.0, 1.0, w/2, h/2)
    
    for _, obs in ipairs(obstacles) do
        love.graphics.draw(obs.data.image, obs.x, obs.y)
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.setNewFont(24)
    love.graphics.print("Score: " .. math.floor(score), 20, 20)
    
    -- POLISHED START SCREEN
        -- POLISHED START SCREEN
        -- POLISHED START SCREEN
    if not started and not gameOver then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        
        -- Title (bigger, higher up)
        love.graphics.setFont(love.graphics.newFont(72))
        local title = "Kitty Run"
        local tw = love.graphics.getFont():getWidth(title)
        
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print(title, 400 - tw/2 + 3, 120 + 3)
        love.graphics.setColor(1, 0.8, 0.3)
        love.graphics.print(title, 400 - tw/2, 120)
        
        -- Subtitle
        love.graphics.setFont(love.graphics.newFont(20))
        local sub = "A purr-fect endless runner"
        local sw = love.graphics.getFont():getWidth(sub)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(sub, 400 - sw/2, 210)
        
        -- Start instruction (no flash)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(28))
        local instr = "PRESS SPACE TO START"
        local iw = love.graphics.getFont():getWidth(instr)
        love.graphics.print(instr, 400 - iw/2, 290)
        
        -- Controls (centered individually)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 1, 1, 0.9)
        
        local controlsTitle = "CONTROLS:"
        local ctW = love.graphics.getFont():getWidth(controlsTitle)
        love.graphics.print(controlsTitle, 400 - ctW/2, 370)
        
        local jumpText = "SPACE = Jump"
        local jtW = love.graphics.getFont():getWidth(jumpText)
        love.graphics.print(jumpText, 400 - jtW/2, 400)
        
        local restartText = "R = Restart (when game over)"
        local rtW = love.graphics.getFont():getWidth(restartText)
        love.graphics.print(restartText, 400 - rtW/2, 430)
        
        -- Made by
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(12))
        local made = "Made by justdev-chris"
        local mw = love.graphics.getFont():getWidth(made)
        love.graphics.print(made, 400 - mw/2, 560)
    end
    
        if gameOver then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.setColor(1, 0.3, 0.3)
        local text = "GAME OVER"
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, 400 - w/2, 200)
        
        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.setColor(1, 1, 1)
        local scoreText = "Score: " .. math.floor(score)
        local sw = love.graphics.getFont():getWidth(scoreText)
        love.graphics.print(scoreText, 400 - sw/2, 280)
        
        love.graphics.setFont(love.graphics.newFont(20))
        local restartText = "Press R to restart"
        local rw = love.graphics.getFont():getWidth(restartText)
        love.graphics.print(restartText, 400 - rw/2, 360)
    end
end

function love.keypressed(key)
    -- SPLASH: skip to start screen
    if splash.active then
        splash.active = false
        return
    end
    
    -- GAME OVER: restart to start screen (no splash)
    if gameOver and key == "r" then
        for _, sound in ipairs(deathSounds) do
            sound:stop()
        end
        love.load()
        gameOver = false
        started = false
        splash.active = false
        return
    end
    
    -- START SCREEN: space starts game
    if not started and not gameOver and key == "space" then
        started = true
    end
end
