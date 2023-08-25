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
    gameState = 'Start'

    -- Game Mode ('Normal', 'Audio Only')
    gameMode = 'Normal'

    -- an object to contain our map data
    map = Map()
    map.frozen = true

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

    -- Ranking screen font
    rankingfont = love.graphics.newFont('/fonts/beatstreet.ttf', 60)

    -- Title screen font
    titlefont = love.graphics.newFont('/fonts/shiny eyes.otf', 200)

    -- Title text font
    titletextfont = love.graphics.newFont('/fonts/smb2.ttf', 30)

    -- How to Play font
    howtoplaytitlefont = love.graphics.newFont('/fonts/unispace bd it.otf', 25)
    howtoplayfont = love.graphics.newFont('/fonts/unispace it.otf', 25)

    -- background image
    background = make_image('graphics/background.jpg')

    -- result screen sound effect
    resultSound = love.audio.newSource('sounds/results.mp3', 'stream')

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
    if gameState ~= "Start" or "GameOver" then
        map:update(dt)
    end

    love.keyboard.keysPressed = {}
end

function love.keypressed(key)    
    if key == 'escape' then
        -- exit the game
        love.event.quit()
    elseif gameState == 'Start' and (key == 'tab' or key == 'w' or key == 's') then 
        gameMode = swap_mode(gameMode)
    elseif gameState == 'Start' and key == 'return' then 
        love.firstRound()
    elseif gameState == 'RoundOver' and key == 'return' then
        -- start a new round unless there have been 5 rounds
        if round < 5 then 
            love.newRound()
        else
            love.gameOver()
        end
    elseif gameState == 'GameOver' and key == 'return' then
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

-- just toggles the gameState from "Start" to "RoundActive", the map and round are already set by love.load()
function love.firstRound()
    gameState = 'RoundActive'
    map.frozen = false  
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
    
    map.frozen = true
    resultSound:play()
end

function love.restart()
    score = 0
    round = 1
    map = Map()
    map.frozen = true
    previousRapper = "None"
    gameState = "Start"
end

function love.draw()
    -- begin virtual resolution drawing
    push:apply('start')

    if gameState == "Start" then
        display_title_screen()
    -- display results screen
    elseif gameState == "GameOver" then 
        display_results()    
    -- in round, prompt the player to find the selected rapper
    elseif gameState == "RoundActive" or "RoundOver" then 
        display_map()
        display_score()
        
        if gameState == "RoundActive" then 
            display_prompt()
        elseif round < 5 then
            display_end_of_round_message()
        else   
            display_end_of_game_message()
        end
    end
    
    -- Used for debugging values in real time
    -- if gameState ~= "Start" then 
    --     love.graphics.print(map.player:collision(map.player.x, map.player.y), VIRTUAL_WIDTH / 2 - 50, 20)
    -- end 
    -- love.graphics.print(map.player.nearestRapperNumber, map.player.x + 30, map.player.y - 30)
    -- love.graphics.print(map.player.collided, VIRTUAL_WIDTH / 2 - 50, 60)
       
    -- end virtual resolution
    push:apply('end')
end

-- display map object
function display_map()
    love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))

    -- draw the background image to the screen
    love.graphics.draw(background, 0,0)
    
    -- renders our map object onto the screen
    map:render()
end 

-- display score overlay
function display_score()
    -- draw scoreboard relative to camera
    colorLtBlue()
    love.graphics.setFont(scoreboardfont)
    love.graphics.printf('Score: ' .. score, math.floor(map.camX), math.floor(map.camY) + 15, VIRTUAL_WIDTH, "center")
end 

-- draw prompt to the center of the screen
function display_prompt()
    colorWhite()
    love.graphics.setFont(promptfont)
    love.graphics.printf('Find ' .. map.selectedRapper.name, 0, map.mapHeightPixels / 2 + 15, map.mapWidthPixels, 'center')
end 

function display_end_of_round_message()
    colorYellow()
    love.graphics.setFont(promptfont)
    love.graphics.printf('Round ' .. round .. ' over', 0, map.mapHeightPixels / 2 + 5, map.mapWidthPixels, 'center')
    love.graphics.printf('Press Enter for next round', 0, map.mapHeightPixels / 2 + 32, map.mapWidthPixels, 'center')
end 

function display_end_of_game_message()
    colorYellow()
    love.graphics.setFont(promptfont)
    love.graphics.printf('Round ' .. round .. ' over', 0, map.mapHeightPixels / 2 + 5, map.mapWidthPixels, 'center')
    love.graphics.printf('Press Enter for final results', 0, map.mapHeightPixels / 2 + 32, map.mapWidthPixels, 'center')    
end 

function display_title_screen()
    map.camX = 0
    map.camY = 0

    title_height = VIRTUAL_HEIGHT / 6
    difficulty_height = VIRTUAL_HEIGHT / 3 + 120
    start_height = VIRTUAL_HEIGHT / 2 + 100
    how_to_play_height = VIRTUAL_HEIGHT / 2 + 180
    line_spacing = 40

    -- title screen
    love.graphics.setFont(titlefont)
    colorYellow()
    love.graphics.printf("Guess Wu?", 0, title_height, VIRTUAL_WIDTH, "center")

    love.graphics.setFont(titletextfont)
    
    if gameMode == "Normal" then 
        colorLtBlue()
        love.graphics.printf("[ Normal ]", 0, difficulty_height, VIRTUAL_WIDTH, "center")
        colorWhite()
        love.graphics.printf("Hard", 0, difficulty_height + line_spacing, VIRTUAL_WIDTH, "center")
    else 
        colorWhite()        
        love.graphics.printf("Normal", 0, difficulty_height, VIRTUAL_WIDTH, "center")
        colorLtBlue()
        love.graphics.printf("[ Hard ]", 0, difficulty_height + line_spacing, VIRTUAL_WIDTH, "center")
    end 

    colorYellow()
    love.graphics.printf("Press Enter to Play", 0, start_height, VIRTUAL_WIDTH, "center")

    colorWhite()
    love.graphics.setFont(howtoplaytitlefont)
    love.graphics.printf("How to Play:", 0, how_to_play_height, VIRTUAL_WIDTH, "center")

    love.graphics.setFont(howtoplayfont)
    love.graphics.printf("Use the ASDW keys to move and touch a rapper to select them", 0, how_to_play_height + line_spacing, VIRTUAL_WIDTH, "center")
    love.graphics.printf("Press Space to play an audio clip from the highlighted rapper", 0, how_to_play_height + (2 * line_spacing), VIRTUAL_WIDTH, "center")
    love.graphics.printf("Press TAB to swap difficulty / Hard difficulty is audio only", 0, how_to_play_height + (3 * line_spacing), VIRTUAL_WIDTH, "center")

end 

function display_results()
    map.camX = 0
    map.camY = 0
    love.graphics.clear()

    -- print victory message
    love.graphics.setFont(promptfont) 
    colorWhite()   
    love.graphics.printf("Your knowledge has earned you the rank:", 0, VIRTUAL_HEIGHT / 4, VIRTUAL_WIDTH, "center")
    
    -- changes font
    love.graphics.setFont(rankingfont)
    colorYellow()
    if score < 16 then
        love.graphics.printf("WU TANG TRAINEE", 0, VIRTUAL_HEIGHT / 4 + 60, VIRTUAL_WIDTH, "center")
    elseif score < 31 then
        love.graphics.printf("WU TANG DISCIPLE", 0, VIRTUAL_HEIGHT / 4 + 60, VIRTUAL_WIDTH, "center")
    elseif score < 41 then
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
    colorLtBlue()
    love.graphics.printf("Total Score: " .. score .. "/50", 0, VIRTUAL_HEIGHT / 2 + lineSpacing, VIRTUAL_WIDTH, "center")

    colorYellow()
    love.graphics.printf("Press Enter to Restart", 0, VIRTUAL_HEIGHT / 2 + lineSpacing + 80, VIRTUAL_WIDTH, "center")

    colorWhite()
end

function swap_mode(current_mode)
    if current_mode == "Normal" then 
        return "Audio Only"
    else 
        return "Normal"
    end 
end 
