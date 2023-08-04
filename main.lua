WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 1280
VIRTUAL_HEIGHT = 720

Class = require 'class'
push = require 'push'

require 'Util'
require 'Player'
require 'Map'

function love.load()
    -- sets a more random seed to make the map generate different layouts each time
    math.randomseed(os.time())

    -- Score tally
    score = 0

    -- Game State ('Start', 'RoundActive', 'RoundOver', 'GameOver')
    gameState = 'RoundActive'

    -- Game Mode ('Normal', 'Audio Only')
    gameMode = 'Audio Only'

    -- an object to contain our map data
    map = Map()

    -- Round number (start at 1 end at 5)
    -- increments upwards on calls of newRound()
    round = 1

    -- array with individual round scores
    roundScores = {}

    -- a variable that holds the name of the last rapper chosen
    previousRapper = 'none'

    -- Scoreboard font
    scoreboardfont = love.graphics.newFont('/fonts/smb2.ttf', 45)

    -- Prompt font
    promptfont = love.graphics.newFont('/fonts/smb2.ttf', 25)
    rankingfont = love.graphics.newFont('/fonts/beatstreet.ttf', 60)

    -- background image
    background = love.graphics.newImage('graphics/background.jpg')

    -- result screen sound effect
    resultSound = love.audio.newSource('sounds/results.mp3', 'static')

    -- makes upscaling look pixel-y instead of blurry
    love.graphics.setDefaultFilter('nearest', 'nearest')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false, 
        vsync = true
    })

    love.keyboard.keysPressed = {}
end

function love.update(dt)
    if gameState ~= "GameOver" then
        map:update(dt)
    end

    love.keyboard.keysPressed = {}
end

function love.keypressed(key)
    if key == 'escape' then
        -- exit the game
        love.event.quit()
    elseif key == 'return' and gameState == 'RoundOver' then
        -- start a new round unless there have been 5 rounds
        if round < 5 then 
            love.newRound()
        else
            love.gameOver()
        end
    elseif key == 'return' and gameState == 'GameOver' then
        -- restart game
        love.restart()
    end

    love.keyboard.keysPressed[key] = true
end

function love.keyreleased(key)
    if key == ('a') or key == ('d') then
        map.player.dx = 0 
    end

    if key == ('w') then 
        map.player.dy = 0
    elseif key == ('s') then
        map.player.dy = 0
    end
    
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

-- sets up a new map, resets the player, creates a new prompt to follow, sets the game status to be in the Round
function love.newRound()
    previousRapper = map.selectedRapper.name
    map = Map()
    gameState = 'RoundActive'
    round = round + 1
end

-- displays the results screen
function love.gameOver()
    gameState = 'GameOver'
    
    if map.player.currentTrack ~= nil then
        map.player.currentTrack:stop()
    end
    
    resultSound:play()
end

function love.restart()
    score = 0
    round = 0
    love.newRound()
end

function love.draw()
    -- begin virtual resolution drawing
    push:apply('start')

    love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))

    -- draw the background image to the screen
    love.graphics.draw(background, 0,0)
    
    -- renders our map object onto the screen
    map:render()
    
    -- draw scoreboard relative to camera
    colorLtBlue()
    love.graphics.setFont(scoreboardfont)
    love.graphics.printf('Score: ' .. score, math.floor(map.camX), math.floor(map.camY) + 15, VIRTUAL_WIDTH, "center")

    -- draw prompt to the center of the screen
    colorWhite()
    love.graphics.setFont(promptfont)
    -- in round, prompt the player to find the selected rapper
    if gameState == "RoundActive" then
        love.graphics.printf('Find ' .. map.selectedRapper.name, 0, map.mapHeightPixels / 2 + 15, map.mapWidthPixels, 'center')
    -- at round end, display that the round is over and prompt the player to press Enter for a new round
    elseif gameState == "RoundOver" and round < 5 then
        colorYellow()
        love.graphics.printf('Round ' .. round .. ' over', 0, map.mapHeightPixels / 2 + 5, map.mapWidthPixels, 'center')
        love.graphics.printf('Press Enter for next round', 0, map.mapHeightPixels / 2 + 32, map.mapWidthPixels, 'center')
        colorWhite()
    elseif gameState == "RoundOver" and round == 5 then
        colorYellow()
        love.graphics.printf('Round ' .. round .. ' over', 0, map.mapHeightPixels / 2 + 5, map.mapWidthPixels, 'center')
        love.graphics.printf('Press Enter for final results', 0, map.mapHeightPixels / 2 + 32, map.mapWidthPixels, 'center')    
        colorWhite()
    end
    
    -- display results screen
    if gameState == "GameOver" then
        map.camX = 0
        map.camY = 0
        love.graphics.clear()

        -- print victory message
        love.graphics.setFont(promptfont)
        
        love.graphics.printf("Your knowledge has earned you the rank:", 0, VIRTUAL_HEIGHT / 4, VIRTUAL_WIDTH, "center")
        
        -- changes font
        love.graphics.setFont(rankingfont)
        colorYellow()
        if score < 16 then
            love.graphics.printf("WU TANG TRAINEE", 0, VIRTUAL_HEIGHT / 4 + 60, VIRTUAL_WIDTH, "center")
        elseif score < 30 then
            love.graphics.printf("WU TANG DISCIPLE", 0, VIRTUAL_HEIGHT / 4 + 60, VIRTUAL_WIDTH, "center")
        elseif score < 40 then
            love.graphics.printf("WU TANG MONK", 0, VIRTUAL_HEIGHT / 4 + 60, VIRTUAL_WIDTH, "center")
        else
            love.graphics.printf("WU TANG MASTER", 0, VIRTUAL_HEIGHT / 4 + 60, VIRTUAL_WIDTH, "center")
        end

        -- print score table
        colorWhite()
        love.graphics.setFont(promptfont)

        local lineSpacing = 0

        for i = 1, 5 do 
            -- this if statement formats the score listing with a space before every non 10 number, so that the digits line up nicely
            if roundScores[i] == 10 then
                love.graphics.printf("Round " .. i .. ": " .. roundScores[i], 0, VIRTUAL_HEIGHT / 2 + lineSpacing, VIRTUAL_WIDTH, "center")
            else 
                love.graphics.printf("Round " .. i .. ":  " .. roundScores[i], 0, VIRTUAL_HEIGHT / 2 + lineSpacing, VIRTUAL_WIDTH, "center")
            end
            lineSpacing = lineSpacing + 30
        end
        love.graphics.printf("Total Score: " .. score .. "/50", 0, VIRTUAL_HEIGHT / 2 + lineSpacing, VIRTUAL_WIDTH, "center")

        colorYellow()
        love.graphics.printf("Press Enter to Restart", 0, VIRTUAL_HEIGHT / 2 + lineSpacing + 80, VIRTUAL_WIDTH, "center")

        colorWhite()
            

    end    
    
    -- Used for debugging values in real time
     --love.graphics.print(previousRapper, VIRTUAL_WIDTH / 2 - 50, 20)
     --love.graphics.print(map.player.nearestRapperNumber, map.player.x + 30, map.player.y - 30)
     --love.graphics.print(map.player.collided, VIRTUAL_WIDTH / 2 - 50, 60)
       
     -- end virtual resolution
    push:apply('end')
end
