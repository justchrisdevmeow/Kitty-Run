-- game.lua
-- Kitty Run - Gameplay module

local game = {}

-- Game variables
game.started = false
game.gameOver = false
game.paused = false
game.score = 0
game.highscore = 0
game.ground = 550
game.audioEnabled = false
game.muted = false

-- Cat
game.cat = { x = 100, y = 0, vy = 0, jumping = false, width = 60, height = 60 }

-- Obstacles
game.obstacles = {}
game.spawnTimer = 0
game.lastMeowScore = 0

-- Animation
game.cat_frame = 1
game.cat_anim_timer = 0

-- Particles
game.dustParticles = {}

-- Clouds
game.clouds = {}
game.cloud_images = {}

-- Assets
game.bg = nil
game.bg_width = 0
game.bg_height = 0
game.cat_frames = {}
game.cat_collision = nil
game.obstacle_types = {}

-- Sounds
game.meowSounds = {}
game.jumpSound = nil
game.deathSounds = {}
game.bgm = nil
game.bgmLoaded = false
game.bgmShouldPlay = false

-- Splash
game.splash = nil

function game.load()
    -- Load background
    game.bg = love.graphics.newImage("assets/images/bg.png")
    game.bg_width = game.bg:getWidth()
    game.bg_height = game.bg:getHeight()
    
    -- Load high score
    if love.filesystem.getInfo("highscore.txt") then
        local content = love.filesystem.read("highscore.txt")
        game.highscore = tonumber(content) or 0
    end
    
    -- Load mute state
    game.muted = false
    if love.filesystem.getInfo("mute.txt") then
        local content = love.filesystem.read("mute.txt")
        game.muted = (content == "true")
        love.audio.setVolume(game.muted and 0 or 1)
    end
    
    -- Load sounds
    game.meowSounds = {
        love.audio.newSource("assets/sounds/meow1.mp3", "static"),
        love.audio.newSource("assets/sounds/meow2.mp3", "static"),
        love.audio.newSource("assets/sounds/meow3.mp3", "static")
    }
    game.jumpSound = love.audio.newSource("assets/sounds/jump.mp3", "static")
    
    game.deathSounds = {
        love.audio.newSource("assets/sounds/death1.mp3", "static"),
        love.audio.newSource("assets/sounds/death2.mp3", "static"),
        love.audio.newSource("assets/sounds/death3.mp3", "static"),
        love.audio.newSource("assets/sounds/death4.mp3", "static")
    }
    for _, sound in ipairs(game.deathSounds) do
        sound:setVolume(0.5)
    end
    
    -- Load background music
    if not game.bgmLoaded then
        game.bgm = love.audio.newSource("assets/sounds/bgm.mp3", "stream")
        game.bgm:setLooping(true)
        game.bgm:setVolume(game.muted and 0 or 0.4)
        game.bgmLoaded = true
    end
    
    -- Load clouds
    for i = 1, 4 do
        game.cloud_images[i] = love.graphics.newImage("assets/images/clouds_" .. i .. ".png")
    end
    game.clouds = {}
    for i = 1, 5 do
        table.insert(game.clouds, {
            x = math.random(0, 800),
            y = math.random(20, 150),
            speed = math.random(10, 40),
            img = game.cloud_images[math.random(1, 4)],
            scale = math.random(5, 15) / 10
        })
    end
    
    -- Load cat and obstacles (using your existing collision map function)
    game.createCollisionMap = function(imgPath)
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
    
    local cat_data = {
        game.createCollisionMap("assets/images/cat1.png"),
        game.createCollisionMap("assets/images/cat2.png")
    }
    game.cat_frames = { cat_data[1].image, cat_data[2].image }
    game.cat_collision = cat_data[1].collision
    local cat_width = cat_data[1].width
    local cat_height = cat_data[1].height
    game.cat.width = cat_width
    game.cat.height = cat_height
    
    local dog_data = game.createCollisionMap("assets/images/dog.png")
    local puddle_data = game.createCollisionMap("assets/images/puddle.png")
    local pickle_data = game.createCollisionMap("assets/images/pickle.png")
    local cactus_data = game.createCollisionMap("assets/images/cactus.png")
    
    game.obstacle_types = {
        { data = dog_data, name = "dog" },
        { data = puddle_data, name = "puddle" },
        { data = pickle_data, name = "pickle" },
        { data = cactus_data, name = "cactus" }
    }
end

function game.start()
    game.started = true
    game.gameOver = false
    game.score = 0
    game.obstacles = {}
    game.cat.y = 0
    game.cat.vy = 0
    game.cat.jumping = false
    game.spawnTimer = 0
    game.dustParticles = {}
    game.lastMeowScore = 0
    game.audioEnabled = false
    game.cat_frame = 1
    
    if game.bgm and not game.bgmShouldPlay then
        game.bgm:play()
        game.bgmShouldPlay = true
    end
    
    gameState = "game"
end

function game.addDust(x, y)
    for i = 1, 2 do
        table.insert(game.dustParticles, {
            x = x + math.random(-15, -5),
            y = y + math.random(-3, 3),
            life = 0.3,
            vx = math.random(-30, 30),
            vy = math.random(-60, -30)
        })
    end
end

function game.update(dt)
    if game.gameOver then
        if love.keyboard.isDown("r") then
            game.start()
        end
        return
    end
    
    -- Update clouds
    for _, c in ipairs(game.clouds) do
        c.x = c.x - c.speed * dt
        if c.x + (c.img:getWidth() * c.scale) < 0 then
            c.x = 900
            c.y = math.random(20, 150)
            c.img = game.cloud_images[math.random(1, 4)]
            c.scale = math.random(5, 15) / 10
        end
    end
    
    -- Dust particles update
    for i = #game.dustParticles, 1, -1 do
        local p = game.dustParticles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.life <= 0 or p.y > game.ground then
            table.remove(game.dustParticles, i)
        end
    end
    
    -- Cat physics
    game.cat.vy = game.cat.vy + 800 * dt
    game.cat.y = game.cat.y + game.cat.vy * dt
    
    if game.cat.y >= game.ground - game.cat.height then
        game.cat.y = game.ground - game.cat.height
        game.cat.jumping = false
        game.cat.vy = 0
        game.addDust(game.cat.x + game.cat.width/2, game.cat.y + game.cat.height)
    end
    
    if game.cat.y < 0 then
        game.cat.y = 0
        game.cat.vy = 0
    end
    
    -- Jump
    if love.keyboard.isDown("space") and not game.cat.jumping then
        if not game.audioEnabled then
            game.audioEnabled = true
            local dummy = love.audio.newSource("assets/sounds/meow1.mp3", "static")
            dummy:play()
            dummy:stop()
        end
        game.cat.vy = -380
        game.cat.jumping = true
        if game.audioEnabled and not game.muted then
            game.jumpSound:stop()
            game.jumpSound:play()
        end
    end
    
    -- Animate cat
    if not game.cat.jumping then
        game.cat_anim_timer = game.cat_anim_timer + dt
        if game.cat_anim_timer > 0.1 then
            game.cat_anim_timer = 0
            game.cat_frame = game.cat_frame + 1
            if game.cat_frame > 2 then game.cat_frame = 1 end
        end
    end
    
    -- Spawn obstacles
    game.spawnTimer = game.spawnTimer + dt
    if game.spawnTimer > 1.5 then
        game.spawnTimer = 0
        local t = game.obstacle_types[math.random(#game.obstacle_types)]
        local spawnX = math.random(800, 1000)
        
        local y_offset = 0
        if t.name == "pickle" then y_offset = -5 end
        if t.name == "puddle" then y_offset = -5 end
        
        table.insert(game.obstacles, {
            x = spawnX,
            y = game.ground - t.data.height + y_offset,
            data = t.data,
            name = t.name
        })
    end
    
    -- Move obstacles
    for i = #game.obstacles, 1, -1 do
        local obs = game.obstacles[i]
        obs.x = obs.x - 250 * dt
        if obs.x + obs.data.width < 0 then
            table.remove(game.obstacles, i)
            game.score = game.score + 10
        end
    end
    
    game.score = game.score + 30 * dt
    
    -- Meow every 500
    local scoreInt = math.floor(game.score)
    if scoreInt >= game.lastMeowScore + 500 then
        game.lastMeowScore = game.lastMeowScore + 500
        if game.audioEnabled and not game.muted then
            local idx = math.random(1, #game.meowSounds)
            game.meowSounds[idx]:stop()
            game.meowSounds[idx]:play()
        end
    end
    
    -- Collision
    for i, obs in ipairs(game.obstacles) do
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
        
        if game.cat.x < obs_right and
           game.cat.x + game.cat.width > obs_left and
           game.cat.y < obs_bottom and
           game.cat.y + game.cat.height > obs_top then
            if game.audioEnabled and not game.muted then
                local idx = math.random(1, #game.deathSounds)
                game.deathSounds[idx]:stop()
                game.deathSounds[idx]:play()
            end
            if math.floor(game.score) > game.highscore then
                game.highscore = math.floor(game.score)
                love.filesystem.write("highscore.txt", tostring(game.highscore))
            end
            game.gameOver = true
            break
        end
    end
end

function game.draw()
    -- Background
    love.graphics.draw(game.bg, (800 - game.bg_width)/2, (600 - game.bg_height)/2)
    
    -- Clouds
    for _, c in ipairs(game.clouds) do
        love.graphics.setColor(1, 1, 1, 0.85)
        love.graphics.draw(c.img, c.x, c.y, 0, c.scale, c.scale)
    end
    love.graphics.setColor(1, 1, 1)
    
    -- Ground
    love.graphics.setColor(0.55, 0.27, 0.07)
    love.graphics.rectangle("fill", 0, game.ground, 800, 600 - game.ground)
    love.graphics.setColor(0.34, 0.55, 0.17)
    love.graphics.rectangle("fill", 0, game.ground - 5, 800, 5)
    
    -- Dust particles
    love.graphics.setColor(0.5, 0.35, 0.2, 0.6)
    for _, p in ipairs(game.dustParticles) do
        love.graphics.circle("fill", p.x, p.y, 2)
    end
    love.graphics.setColor(1, 1, 1)
    
    -- Cat
    local w = game.cat_frames[game.cat_frame]:getWidth()
    local h = game.cat_frames[game.cat_frame]:getHeight()
    love.graphics.draw(game.cat_frames[game.cat_frame], game.cat.x + game.cat.width/2, game.cat.y + game.cat.height/2 - 5, 0, 1.0, 1.0, w/2, h/2)
    
    -- Obstacles
    for _, obs in ipairs(game.obstacles) do
        love.graphics.draw(obs.data.image, obs.x, obs.y)
    end
    
    -- Score
    love.graphics.setColor(0, 0, 0)
    love.graphics.setNewFont(24)
    love.graphics.print("Score: " .. math.floor(game.score), 20, 20)
    love.graphics.print("Best: " .. game.highscore, 20, 50)
    
    -- Mute button
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 740, 20, 50, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(12)
    if game.muted then
        love.graphics.print("MUTE", 748, 28)
    else
        love.graphics.print("SOUND", 743, 28)
    end
    love.graphics.setNewFont(24)
    
    -- Game Over
    if game.gameOver then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.setNewFont(48)
        local text = "GAME OVER"
        local w = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, 400 - w/2, 200)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(32)
        local scoreText = "Score: " .. math.floor(game.score)
        local sw = love.graphics.getFont():getWidth(scoreText)
        love.graphics.print(scoreText, 400 - sw/2, 280)
        love.graphics.setNewFont(20)
        local restartText = "Press R to restart"
        local rw = love.graphics.getFont():getWidth(restartText)
        love.graphics.print(restartText, 400 - rw/2, 360)
    end
end

function game.drawPauseOverlay()
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(32)
    love.graphics.print("PAUSED", 350, 280)
    love.graphics.setNewFont(16)
    love.graphics.print("Press ESC to resume", 330, 330)
end

function game.updatePaused(dt)
    -- Nothing updates while paused
end

function game.resume()
    gameState = "game"
end

function game.keypressed(key)
    if key == "escape" then
        gameState = "paused"
    elseif key == "m" then
        game.muted = not game.muted
        love.audio.setVolume(game.muted and 0 or 1)
        if game.bgm then
            game.bgm:setVolume(game.muted and 0 or 0.4)
        end
        love.filesystem.write("mute.txt", tostring(game.muted))
    end
end

function game.mousepressed(x, y, button)
    -- Check mute button
    if button == 1 and x >= 740 and x <= 790 and y >= 20 and y <= 50 then
        game.muted = not game.muted
        love.audio.setVolume(game.muted and 0 or 1)
        if game.bgm then
            game.bgm:setVolume(game.muted and 0 or 0.4)
        end
        love.filesystem.write("mute.txt", tostring(game.muted))
    end
end

function game.setSFXVolume(volume)
    for _, sound in ipairs(game.meowSounds) do
        sound:setVolume(volume)
    end
    game.jumpSound:setVolume(volume)
    for _, sound in ipairs(game.deathSounds) do
        sound:setVolume(volume * 0.5)
    end
end

function game.setBGMVolume(volume)
    if game.bgm then
        game.bgm:setVolume(volume)
    end
end

return game