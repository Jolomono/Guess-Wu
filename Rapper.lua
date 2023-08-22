Rapper = Class{}

AUDIO_ICON = make_image('graphics/now_playing2.png')
HIDDEN_TEXTURE = make_image('graphics/hidden.png')
HIDDEN_SELECTED_TEXTURE = make_image('graphics/hidden2.png')

TEXTURES = { 
    ["RZA"] = { ["texture"] = make_image('graphics/rza.png'),
            ["selected"] = make_image('graphics/rza2.png')
    }, 
    ["GZA"] = { ["texture"] = make_image('graphics/gza.png'),
            ["selected"] = make_image('graphics/gza2.png')
    },
    ["Ghostface Killah"] = { ["texture"] = make_image('graphics/ghostface.png'),
            ["selected"] = make_image('graphics/ghostface2.png')
    },
    ["Method Man"] = { ["texture"] = make_image('graphics/methodman.png'),
            ["selected"] = make_image('graphics/methodman2.png')
    },
    ["Ol' Dirty Bastard"] = { ["texture"] = make_image('graphics/odb.png'),
            ["selected"] = make_image('graphics/odb2.png')
    },
    ["Raekwon"] = { ["texture"] = make_image('graphics/raekwon.png'),
            ["selected"] = make_image('graphics/raekwon2.png')
    },
    ["Inspectah Deck"] = { ["texture"] = make_image('graphics/inspectahdeck.png'),
            ["selected"] = make_image('graphics/inspectahdeck2.png')
    },
    ["U-God"] = { ["texture"] = make_image('graphics/u-god.png'),
            ["selected"] = make_image('graphics/u-god2.png')
    },
    ["Masta Killa"] = { ["texture"] = make_image('graphics/mastakilla.png'),
            ["selected"] = make_image('graphics/mastakilla2.png')
    },
    ["Cappadonna"] = { ["texture"] = make_image('graphics/cappadonna.png'),
            ["selected"] = make_image('graphics/cappadonna2.png')
    },
    ["David Lee Roth"] = { ["texture"] = make_image('graphics/davidleeroth.png'),
            ["selected"] = make_image('graphics/davidleeroth2.png')
    },
    ["Paul Stanley"] = { ["texture"] = make_image('graphics/paulstanley.png'),
            ["selected"] = make_image('graphics/paulstanley2.png')
    }
}

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

    -- Is this rapper nearest to the player?
    self.selected = false

    -- Is this rapper currently playing audio?
    self.playing = false 

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
    self.texture = TEXTURES[name]["texture"]
    self.selectedtexture = TEXTURES[name]["selected"]

    -- verses audio table setup
    -- this is on a separate file because of how many audio files there are
    self.audio = setupAudio(self.name)
    
    -- number of verses in the rapper's audio table
    self.total_verses = table.getn(self.audio)
    
    -- font 
    nameplatefont = love.graphics.newFont("/fonts/shiny eyes.otf", 44)
    
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

function Rapper:update()
    if self.status == 'revealed' then
        self.nameplate = self.name
    end

    if map.player.nearestRapper == self then
         self.selected = true 
    else
         self.selected = false
    end
end

function Rapper:render()
    love.graphics.setFont(nameplatefont)
    love.graphics.printf(self.nameplate, self.x - 50, self.y + self.height, self.width + 100, "center")

    if self.playing == true then 
        love.graphics.draw(AUDIO_ICON, self.x + self.width + 10, self.y + 50, 0, 1, 1)
        love.graphics.draw(AUDIO_ICON, self.x - 10, self.y + 50, 0, -1, 1)
    end 
    
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
            love.graphics.draw(HIDDEN_SELECTED_TEXTURE, self.x, self.y, 0, 1, 1)
        else
            love.graphics.draw(HIDDEN_TEXTURE, self.x, self.y, 0, 1, 1)
        end    
    end
end

function Rapper:stop_playing()
    self.playing = false
end 

function Rapper:start_playing()
    self.playing = true
end 