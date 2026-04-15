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
    
    -- CLOUDS (multiple types, more spread out)
    cloud_images = {}
    for i = 1, 4 do
        cloud_images[i] = love.graphics.newImage("assets/images/clouds_" .. i .. ".png")
    end
    clouds = {}
    for i = 1, 5 do
        table.insert(clouds, {
            x = math.random(0, 800),
            y = math.random(20, 150),
            speed = math.random(10, 40),
            img = cloud_images[math.random(1, 4)],
            scale = math.random(5, 15) / 10
        })
    end
    
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
        
        -- Make white pixels transparent for drawing
        for y = 0, height - 1 do
            for x = 0, width - 1 do
                local r, g, b, a = imgData:getPixel(x, y)
                if r > 0.95 and g > 0.95 and b > 0.95 then
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
    
    -- HIGH SCORE
    highscore = 0
    if love.filesystem.getInfo("highscore.txt") then
        local content = love.filesystem.read("highscore.txt")
        highscore = tonumber(content) or 0
    end
    
    -- MUTE STATE
    muted = false
    if love.filesystem.getInfo("mute.txt") then
        local content = love.filesystem.read("mute.txt")
        muted = (content == "true")
        love.audio.setVolume(muted and 0 or 1)
    end
    
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
    paused = false
    obstacles = {}
    spawnTimer = 0
    dustParticles = {}
    
    love.window.setMode(800, 600)
    
    splash.active = true
    splash.timer = 0
end

function addDust(x, y)
    for i = 1, 2 do
        table.insert(dustParticles, {
            x = x + math.random(-15, -5),
            y = y + math.random(-3, 3),
            life = 0.3,
            vx = math.random(-30, 30),
            vy = math.random(-60, -30)
        })
    end
end

function love.update(dt)
    if dt > 0.033 then dt = 0.033 end
    
    if splash.active then
        splash.timer = splash.timer + dt
        if splash.timer >= splash.duration then
            splash.active = false
        end
        return
    end
    
    if paused then return end
    
    if gameOver then return end
    
    if not started then
        if love.keyboard.isDown("space") then
            started = true
        end
        return
    end
    
    -- Update clouds (spread apart by adjusting respawn)
    for _, c in ipairs(clouds) do
        c.x = c.x - c.speed * dt
        if c.x + (c.img:getWidth() * c.scale) < 0 then
            c.x = 900  -- Spawn further right (was 800)
            c.y = math.random(20, 150)
            c.img = cloud_images[math.random(1, 4)]
            c.scale = math.random(5, 15) / 10
        end
    end
    
    -- Dust particles update
    for i = #dustParticles, 1, -1 do
        local p = dustParticles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.life <= 0 or p.y > ground then
            table.remove(dustParticles, i)
        end
    end
    
    cat.vy = cat.vy + 800 * dt
    cat.y = cat.y + cat.vy * dt
    
    if cat.y >= ground - cat.height then
        cat.y = ground - cat.height
        cat.jumping = false
        cat.vy = 0
        addDust(cat.x + cat.width/2, cat.y + cat.height)
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
        if audioEnabled and not muted then
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
        if audioEnabled and not muted then
            local idx = math.random(1, #meowSounds)
            meowSounds[idx]:stop()
            meowSounds[idx]:play()
        end
    end
    
    for i, obs in ipairs(obstacles) do
        local y_shrink = 10
        if obs.name == "puddle" then
            y_shrink = 45
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
            if audioEnabled and not muted then
                local idx = math.random(1, #deathSounds)
                deathSounds[idx]:stop()
                deathSounds[idx]:play()
            end
            if math.floor(score) > highscore then
                highscore = math.floor(score)
                love.filesystem.write("highscore.txt", tostring(highscore))
            end
            gameOver = true
            break
        end
    end
end

function love.draw()
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
    
    -- Draw clouds
    for _, c in ipairs(clouds) do
        love.graphics.setColor(1, 1, 1, 0.85)
        love.graphics.draw(c.img, c.x, c.y, 0, c.scale, c.scale)
    end
    love.graphics.setColor(1, 1, 1)
    
    love.graphics.setColor(0.55, 0.27, 0.07)
    love.graphics.rectangle("fill", 0, ground, 800, 600 - ground)
    love.graphics.setColor(0.34, 0.55, 0.17)
    love.graphics.rectangle("fill", 0, ground - 5, 800, 5)
    
    -- Dust particles
    love.graphics.setColor(0.5, 0.35, 0.2, 0.6)
    for _, p in ipairs(dustParticles) do
        love.graphics.circle("fill", p.x, p.y, 2)
    end
    love.graphics.setColor(1, 1, 1)
    
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
    love.graphics.print("Best: " .. highscore, 20, 50)
    
    -- Mute button
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 740, 20, 50, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(12)
    if muted then
        love.graphics.print("MUTE", 748, 28)
    else
        love.graphics.print("SOUND", 743, 28)
    end
    love.graphics.setNewFont(24)
    
    -- Pause indicator
    if paused then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(32)
        love.graphics.print("PAUSED", 350, 280)
        love.graphics.setNewFont(16)
        love.graphics.print("Press ESC to resume", 340, 330)
    end
    
    if not started and not gameOver then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.setNewFont(48)
        local title = "Kitty Run"
        local tw = love.graphics.getFont():getWidth(title)
        love.graphics.print(title, 400 - tw/2, 180)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(24)
        local instr = "Press SPACE to Start"
        local iw = love.graphics.getFont():getWidth(instr)
        love.graphics.print(instr, 400 - iw/2, 280)
        love.graphics.setNewFont(18)
        local jump = "Press SPACE to jump over obstacles"
        local jw = love.graphics.getFont():getWidth(jump)
        love.graphics.print(jump, 400 - jw/2, 340)
        local score_text = "Collect points by surviving longer"
        local sw = love.graphics.getFont():getWidth(score_text)
        love.graphics.print(score_text, 400 - sw/2, 370)
        love.graphics.setNewFont(14)
        local restart = "Press R to restart after game over"
        local rw = love.graphics.getFont():getWidth(restart)
        love.graphics.print(restart, 400 - rw/2, 420)
        local esc_text = "ESC = Pause  |  M = Mute"
        local ew = love.graphics.getFont():getWidth(esc_text)
        love.graphics.print(esc_text, 400 - ew/2, 450)
    end
    
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.setNewFont(48)
        local text = "GAME OVER"
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, 400 - w/2, 200)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(32)
        local scoreText = "Score: " .. math.floor(score)
        local sw = love.graphics.getFont():getWidth(scoreText)
        love.graphics.print(scoreText, 400 - sw/2, 280)
        love.graphics.setNewFont(20)
        local restartText = "Press R to restart"
        local rw = love.graphics.getFont():getWidth(restartText)
        love.graphics.print(restartText, 400 - rw/2, 360)
    end
end

function love.keypressed(key)
    if splash.active then
        splash.active = false
        return
    end
    
    if key == "escape" then
        if not gameOver and started then
            paused = not paused
        end
        return
    end
    
    if key == "m" then
        muted = not muted
        love.audio.setVolume(muted and 0 or 1)
        love.filesystem.write("mute.txt", tostring(muted))
        return
    end
    
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
    
    if not started and not gameOver and key == "space" then
        started = true
    end
end
