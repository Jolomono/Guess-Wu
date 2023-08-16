Rapper = Class{}

function Rapper:init(map, name, number)
    -- name
    self.name = name

    -- shown name
    self.nameplate = "? ? ?"

    -- status 'revealed' 'hidden'
    self.status = 'hidden'

    -- number for the rapper, I'm thinking four total, this will determine his location
    self.number = number

    -- height and width of image
    self.width = 150
    self.height = 150

    self.selected = false

    -- location for sprite
    if self.number == 1 then
        self.x = math.random(50, map.mapWidthPixels / 2 - self.width - 50)
        self.y = math.random(50, map.mapHeightPixels / 2 - self.height - 50)
    elseif self.number == 2 then
        self.x = math.random(map.mapWidthPixels / 2 + 50, map.mapWidthPixels - self.width - 50)
        self.y = math.random(50, map.mapHeightPixels / 2 - self.height - 50)
    elseif self.number == 3 then
        self.x = math.random(map.mapWidthPixels / 2 + 50, map.mapWidthPixels - self.width - 50)
        self.y = math.random(map.mapHeightPixels / 2 + 50, map.mapHeightPixels - self.height - 50)
    else 
        self.x = math.random(50, map.mapWidthPixels / 2 - self.width - 50)
        self.y = math.random(map.mapHeightPixels / 2 + 50, map.mapHeightPixels - self.height - 50)
    end

    self.middlex = self.x + self.width / 2
    self.middley = self.y + self.height / 2
    
    -- texture file setup
    self:setupTexture(self.name)

    -- verses audio table setup
    -- this is on a separate file because of how many audio files there are
    self.audio = setupAudio(self.name)
    
    -- number of verses in the rapper's audio table
    self.total_verses = table.getn(self.audio)

    self.hiddentexture = love.graphics.newImage('graphics/hidden.png')
    self.hiddenselectedtexture = love.graphics.newImage('graphics/hidden2.png')
    
    -- font 
    nameplatefont = love.graphics.newFont("/fonts/shiny eyes.otf", 44)
    
end

-- sets up the texture file to use for each rapper
function Rapper:setupTexture(name)
    if name == 'RZA' then
        self.texture = love.graphics.newImage('graphics/rza.png')
        self.selectedtexture = love.graphics.newImage('graphics/rza2.png')
    elseif name == 'GZA' then
        self.texture = love.graphics.newImage('graphics/gza.png')
        self.selectedtexture = love.graphics.newImage('graphics/gza2.png')
    elseif name == 'Ghostface Killah' then
        self.texture = love.graphics.newImage('graphics/ghostface.png')
        self.selectedtexture = love.graphics.newImage('graphics/ghostface2.png')
    elseif name == 'Method Man' then
        self.texture = love.graphics.newImage('graphics/methodman.png')
        self.selectedtexture = love.graphics.newImage('graphics/methodman2.png')
    elseif name == "Ol' Dirty Bastard" then
        self.texture = love.graphics.newImage('graphics/odb.png')
        self.selectedtexture = love.graphics.newImage('graphics/odb2.png')
    elseif name == 'Raekwon' then
        self.texture = love.graphics.newImage('graphics/raekwon.png')
        self.selectedtexture = love.graphics.newImage('graphics/raekwon2.png')
    elseif name == 'Inspectah Deck' then
        self.texture = love.graphics.newImage('graphics/inspectahdeck.png')
        self.selectedtexture = love.graphics.newImage('graphics/inspectahdeck2.png')
    elseif name == 'U-God' then
        self.texture = love.graphics.newImage('graphics/u-god.png')
        self.selectedtexture = love.graphics.newImage('graphics/u-god2.png')
    elseif name == 'Masta Killa' then
        self.texture = love.graphics.newImage('graphics/mastakilla.png')
        self.selectedtexture = love.graphics.newImage('graphics/mastakilla2.png')
    elseif name == 'Cappadonna' then
        self.texture = love.graphics.newImage('graphics/cappadonna.png')
        self.selectedtexture = love.graphics.newImage('graphics/cappadonna2.png')
    elseif name == 'David Lee Roth' then
        self.texture = love.graphics.newImage('graphics/davidleeroth.png')
        self.selectedtexture = love.graphics.newImage('graphics/davidleeroth2.png')
    elseif name == 'Paul Stanley' then
        self.texture = love.graphics.newImage('graphics/paulstanley.png')
        self.selectedtexture = love.graphics.newImage('graphics/paulstanley2.png')
    end
end

-- if a rapper has been touched, change status to 'revealed'
-- if the rapper is the prompted rapper, update the score and mark the round as over
function Rapper:touched(attempt)
    if self.status == 'hidden' then 
        self.status = 'revealed'
        if self.name == map.selectedRapper.name then
            if attempt == 1 then
                roundScores[round] = 10
                score = score + 10
            elseif attempt == 2 then
                roundScores[round] = 5
                score = score + 5
            elseif attempt == 3 then
                roundScores[round] = 3
                score = score + 3
            else
                roundScores[round] = 0
                score = score + 0
            end
            if map.player.currentTrack ~= nil then
                map.player.currentTrack:stop()
            end
            
            map.player.sounds['correct']:play()
            gameState = "RoundOver"
        else
            if map.player.currentTrack ~= nil then
                map.player.currentTrack:stop()
            end
    
            map.player.sounds['wrong']:play()
        end
    end
    
end

function Rapper:update(number)
    if self.status == 'revealed' then
        self.nameplate = self.name
    end

    if number == self.number then
        self.selected = true 
    else
        self.selected = false
    end
end

function Rapper:render()
    love.graphics.setFont(nameplatefont)
    love.graphics.printf(self.nameplate, self.x - 50, self.y + self.height, self.width + 100, "center")
    
    -- determines what to draw to the screen for each rapper based on the status
    -- if the rapper is revealed their picture should show up in Audio Only mode or Normal mode
    if self.status == 'revealed' or gameMode == 'Normal' then
        if self.selected then
            love.graphics.draw(self.selectedtexture, self.x, self.y, 0, 1, 1)
        else
            love.graphics.draw(self.texture, self.x, self.y, 0, 1, 1)
        end
    -- if the game mode isn't normal (and thus it's in 'Audio Only' mode) and the rapper hasn't been revealed then use the hidden textures for each rapper
    else 
        if self.selected then
            love.graphics.draw(self.hiddenselectedtexture, self.x, self.y, 0, 1, 1)
        else
            love.graphics.draw(self.hiddentexture, self.x, self.y, 0, 1, 1)
        end    
    end
end