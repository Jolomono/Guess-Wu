Class = require 'class'
push = require 'push'

require 'util'
require 'player'
require 'map'

-- Fonts
PROMPT_FONT = love.graphics.newFont('/fonts/smb2.ttf', 25)
TITLE_FONT = love.graphics.newFont('/fonts/shiny eyes.otf', 200)
TITLE_TEXT_FONT = love.graphics.newFont('/fonts/smb2.ttf', 30)

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 1280
VIRTUAL_HEIGHT = 720

function love.load()
    -- sets a more random seed to make the map generate different layouts each time
    math.randomseed(os.time())

    -- Score tally
    score = 0

    -- Game State ('Start', 'Round Active', 'Round Over', 'Game Over')
    game_state = 'Start'

    -- Game Mode ('Normal', 'Audio Only')
    game_mode = 'Normal'

    -- an object to contain our map data
    map = Map()
    map.frozen = true

    -- Round number (start at 1 end at 5)
    -- increments upwards on calls of new_round()
    round = 1 

    -- array with individual round scores
    round_scores = {}

    -- a variable that holds the name of the last rapper chosen
    previous_rapper = nil   

    -- background image
    background = make_image('graphics/background.jpg')

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
    if game_state ~= "Start" or "Game Over" then
        map:update(dt)
    end

    love.keyboard.keysPressed = {}
end

function love.keypressed(key)
    if key == 'escape' then
        -- exit the game
        love.event.quit()
    elseif game_state == 'Start' and (key == 'tab' or key == 'w' or key == 's') then
        game_mode = swap_mode(game_mode)
    elseif game_state == 'Start' and key == 'return' then
        love.first_round()
    elseif game_state == 'Round Over' and key == 'return' then
        -- start a new round unless there have been 5 rounds
        if round < 5 then
            love.new_round()
        else
            love.game_over()
        end
    elseif game_state == 'Game Over' and key == 'return' then
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

-- just toggles the game_state from "Start" to "Round Active", the map and round are already set by love.load()
function love.first_round()
    game_state = 'Round Active'
    map.frozen = false
end

-- sets up a new map, resets the player, creates a new prompt to follow, sets the game status to be in the Round
function love.new_round()
    previous_rapper = map.selected_rapper.name
    map = Map()
    game_state = 'Round Active'
    round = round + 1
end

-- displays the results screen
function love.game_over()
    game_state = 'Game Over'

    if map.player.current_track ~= nil then
        map.player.current_track:stop()
    end

    map.frozen = true

    -- result screen sound effect
    local result_sound = love.audio.newSource('sounds/results.mp3', 'stream')

    result_sound:play()
end

function love.restart()
    score = 0
    round = 1
    map = Map()
    map.frozen = true
    previous_rapper = nil
    game_state = "Start"
end

function love.draw()
    -- begin virtual resolution drawing
    push:apply('start')

    if game_state == "Start" then
        display_title_screen()
    -- display results screen
    elseif game_state == "Game Over" then 
        display_results()    
    -- in round, prompt the player to find the selected rapper
    elseif game_state == "Round Active" or "Round Over" then 
        display_map()
        display_score()
        
        if game_state == "Round Active" then 
            display_prompt()
        elseif round < 5 then
            display_end_of_round_message()
        else   
            display_end_of_game_message()
        end
    end
    
    -- Used for debugging values in real time
    -- if game_state ~= "Start" then 
    --     love.graphics.print(map.player:collision(map.player.x, map.player.y), VIRTUAL_WIDTH / 2 - 50, 20)
    -- end 
    -- love.graphics.print(map.player.nearestRapperNumber, map.player.x + 30, map.player.y - 30)
    -- love.graphics.print(map.player.collided, VIRTUAL_WIDTH / 2 - 50, 60)
       
    -- end virtual resolution
    push:apply('end')
end

-- display map object
function display_map()
    love.graphics.translate(math.floor(-map.cam_x), math.floor(-map.cam_y))

    -- draw the background image to the screen
    love.graphics.draw(background, 0,0)
    
    -- renders our map object onto the screen
    map:render()
end 

-- display score overlay
function display_score()
    -- scoreboard font
    local font = love.graphics.newFont('/fonts/smb2.ttf', 45)

    -- draw scoreboard relative to camera
    color_lt_blue()
    love.graphics.setFont(font)
    love.graphics.printf('Score: ' .. score, math.floor(map.cam_x), math.floor(map.cam_y) + 15, VIRTUAL_WIDTH, "center")
end 

-- draw prompt to the center of the screen
function display_prompt()
    color_white()
    love.graphics.setFont(PROMPT_FONT)
    love.graphics.printf('Find ' .. map.selected_rapper.name, 0, map.height / 2 + 15, map.width, 'center')
end 

function display_end_of_round_message()
    color_yellow()
    love.graphics.setFont(PROMPT_FONT)
    love.graphics.printf('Round ' .. round .. ' over', 0, map.height / 2 + 5, map.width, 'center')
    love.graphics.printf('Press Enter for next round', 0, map.height / 2 + 32, map.width, 'center')
end 

function display_end_of_game_message()
    color_yellow()
    love.graphics.setFont(PROMPT_FONT)
    love.graphics.printf('Round ' .. round .. ' over', 0, map.height / 2 + 5, map.width, 'center')
    love.graphics.printf('Press Enter for final results', 0, map.height / 2 + 32, map.width, 'center')    
end 

function display_title_screen()
    map.cam_x = 0
    map.cam_y = 0

    local title_height = VIRTUAL_HEIGHT / 6
    local difficulty_height = VIRTUAL_HEIGHT / 3 + 120
    local start_height = VIRTUAL_HEIGHT / 2 + 100
    local how_to_play_height = VIRTUAL_HEIGHT / 2 + 180
    local line_spacing = 40

    -- title logo
    color_yellow()
    love.graphics.setFont(TITLE_FONT)
    love.graphics.printf("Guess Wu?", 0, title_height, VIRTUAL_WIDTH, "center")
    
    -- difficulty selection
    love.graphics.setFont(TITLE_TEXT_FONT)

    if game_mode == "Normal" then 
        color_lt_blue()
        love.graphics.printf("[ Normal ]", 0, difficulty_height, VIRTUAL_WIDTH, "center")
        color_white()
        love.graphics.printf("Hard", 0, difficulty_height + line_spacing, VIRTUAL_WIDTH, "center")
    else 
        color_white()        
        love.graphics.printf("Normal", 0, difficulty_height, VIRTUAL_WIDTH, "center")
        color_lt_blue()
        love.graphics.printf("[ Hard ]", 0, difficulty_height + line_spacing, VIRTUAL_WIDTH, "center")
    end 

    -- play prompt
    color_yellow()
    love.graphics.printf("Press Enter to Play", 0, start_height, VIRTUAL_WIDTH, "center")

    -- how to play instructions
    -- How to Play font
    local how_to_play_title_font = love.graphics.newFont('/fonts/unispace bd it.otf', 25)
    local how_to_play_font = love.graphics.newFont('/fonts/unispace it.otf', 25)


    color_white()
    love.graphics.setFont(how_to_play_title_font)
    love.graphics.printf("How to Play:", 0, how_to_play_height, VIRTUAL_WIDTH, "center")

    love.graphics.setFont(how_to_play_font)
    love.graphics.printf("Use the ASDW keys to move and touch a rapper to select them", 0, how_to_play_height + line_spacing, VIRTUAL_WIDTH, "center")
    love.graphics.printf("Press Space to play an audio clip from the highlighted rapper", 0, how_to_play_height + (2 * line_spacing), VIRTUAL_WIDTH, "center")
    love.graphics.printf("Press TAB to swap difficulty / Hard difficulty is audio only", 0, how_to_play_height + (3 * line_spacing), VIRTUAL_WIDTH, "center")
end 

function display_results()
    map.cam_x = 0
    map.cam_y = 0
    love.graphics.clear()

    -- print victory message
    love.graphics.setFont(PROMPT_FONT) 
    color_white()   
    love.graphics.printf("Your knowledge has earned you the rank:", 0, VIRTUAL_HEIGHT / 4, VIRTUAL_WIDTH, "center")
    
    -- ranking font
    local ranking_font = love.graphics.newFont('/fonts/beatstreet.ttf', 60)
    love.graphics.setFont(ranking_font)
    color_yellow()
    
    -- ranking label
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
    color_white()
    love.graphics.setFont(PROMPT_FONT)

    local lineSpacing = 0

    for i = 1, 5 do 
        -- this if statement formats the score listing with a space before every non 10 number, so that the digits line up nicely
        if round_scores[i] == 10 then
            love.graphics.printf("Round " .. i .. ": " .. round_scores[i], 0, VIRTUAL_HEIGHT / 2 + lineSpacing, VIRTUAL_WIDTH, "center")
        else 
            love.graphics.printf("Round " .. i .. ":  " .. round_scores[i], 0, VIRTUAL_HEIGHT / 2 + lineSpacing, VIRTUAL_WIDTH, "center")
        end
        lineSpacing = lineSpacing + 30
    end
    color_lt_blue()
    love.graphics.printf("Total Score: " .. score .. "/50", 0, VIRTUAL_HEIGHT / 2 + lineSpacing, VIRTUAL_WIDTH, "center")

    color_yellow()
    love.graphics.printf("Press Enter to Restart", 0, VIRTUAL_HEIGHT / 2 + lineSpacing + 80, VIRTUAL_WIDTH, "center")
end

function swap_mode(current_mode)
    if current_mode == "Normal" then 
        return "Audio Only"
    else 
        return "Normal"
    end 
end 
