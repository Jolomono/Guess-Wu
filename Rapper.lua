Rapper = Class{}

AUDIO_ICON = make_image('graphics/now_playing2.png')
HIDDEN_TEXTURE = make_image('graphics/hidden.png')
HIDDEN_SELECTED_TEXTURE = make_image('graphics/hidden2.png')
NAMEPLATE_FONT = love.graphics.newFont("/fonts/shiny eyes.otf", 44)

RAPPER_TABLE = { 
    ["RZA"] = { ["texture"] = make_image('graphics/rza.png'),
            ["selected"] = make_image('graphics/rza2.png'), 
            ["audio"] = make_audio_table("/verses/rza/", 20)
    }, 
    ["GZA"] = { ["texture"] = make_image('graphics/gza.png'),
            ["selected"] = make_image('graphics/gza2.png'),
            ["audio"] = make_audio_table("/verses/gza/", 23)
    },
    ["Ghostface Killah"] = { ["texture"] = make_image('graphics/ghostface.png'),
            ["selected"] = make_image('graphics/ghostface2.png'),
            ["audio"] = make_audio_table("/verses/ghostface/", 29)
    },
    ["Method Man"] = { ["texture"] = make_image('graphics/methodman.png'),
            ["selected"] = make_image('graphics/methodman2.png'),
            ["audio"] = make_audio_table("/verses/method_man/", 42)
    },
    ["Ol' Dirty Bastard"] = { ["texture"] = make_image('graphics/odb.png'),
            ["selected"] = make_image('graphics/odb2.png'),
            ["audio"] = make_audio_table("/verses/odb/", 24)
    },
    ["Raekwon"] = { ["texture"] = make_image('graphics/raekwon.png'),
            ["selected"] = make_image('graphics/raekwon2.png'),
            ["audio"] = make_audio_table("/verses/raekwon/", 24)
    },
    ["Inspectah Deck"] = { ["texture"] = make_image('graphics/inspectahdeck.png'),
            ["selected"] = make_image('graphics/inspectahdeck2.png'),
            ["audio"] = make_audio_table("/verses/inspectah_deck/", 22)
    },
    ["U-God"] = { ["texture"] = make_image('graphics/u-god.png'),
            ["selected"] = make_image('graphics/u-god2.png'),
            ["audio"] = make_audio_table("/verses/u-god/", 25)
    },
    ["Masta Killa"] = { ["texture"] = make_image('graphics/mastakilla.png'),
            ["selected"] = make_image('graphics/mastakilla2.png'),
            ["audio"] = make_audio_table("/verses/masta_killa/", 28)
    },
    ["Cappadonna"] = { ["texture"] = make_image('graphics/cappadonna.png'),
            ["selected"] = make_image('graphics/cappadonna2.png'),
            ["audio"] = make_audio_table("/verses/cappadonna/", 12)
    },
    ["David Lee Roth"] = { ["texture"] = make_image('graphics/davidleeroth.png'),
            ["selected"] = make_image('graphics/davidleeroth2.png'),
            ["audio"] = make_audio_table("/verses/david_lee_roth/", 33)
    },
    ["Paul Stanley"] = { ["texture"] = make_image('graphics/paulstanley.png'),
            ["selected"] = make_image('graphics/paulstanley2.png'),
            ["audio"] = make_audio_table("/verses/paul_stanley/", 32)
    }
}

function Rapper:init(map, name, number)
    -- name
    self.name = name

    -- shown name
    self.nameplate = "? ? ?"

    -- status 'revealed' 'hidden'
    self.status = 'hidden'

    -- number for the rapper, this will determine his location
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
        self.x = math.random(50, map.width / 2 - self.width - 50)
        self.y = math.random(50, map.height / 2 - self.height - 50)
    elseif self.number == 2 then
        self.x = math.random(map.width / 2 + 50, map.width - self.width - 50)
        self.y = math.random(50, map.height / 2 - self.height - 50)
    elseif self.number == 3 then
        self.x = math.random(map.width / 2 + 50, map.width - self.width - 50)
        self.y = math.random(map.height / 2 + 50, map.height - self.height - 50)
    else 
        self.x = math.random(50, map.width / 2 - self.width - 50)
        self.y = math.random(map.height / 2 + 50, map.height - self.height - 50)
    end

    self.middlex = self.x + self.width / 2
    self.middley = self.y + self.height / 2

    self.left_edge = self.x 
    self.right_edge = self.x + self.width 
    self.top_edge = self.y 
    self.bottom_edge = self.y + self.height
    
    -- texture file setup
    self.texture = RAPPER_TABLE[name]["texture"]
    self.selected_texture = RAPPER_TABLE[name]["selected"]

    -- creates a shuffled audio table 
    self.audio = shuffle_table(RAPPER_TABLE[name]["audio"])
                    
    -- number of verses in the rapper's audio table
    self.total_verses = table.getn(self.audio)

    -- track marker, iterates after each track play to cycle through verses in table
    self.track_num = 1
end

-- if a rapper has been touched, change status to 'revealed'
-- if the rapper is the prompted rapper, update the score and mark the round as over
function Rapper:touched(attempt)
    if self.status == 'hidden' then 
        self.status = 'revealed'
        if self.name == map.selected_rapper.name then
            if attempt == 1 then
                round_scores[round] = 10
                score = score + 10
            elseif attempt == 2 then
                round_scores[round] = 5
                score = score + 5
            elseif attempt == 3 then
                round_scores[round] = 3
                score = score + 3
            else
                round_scores[round] = 0
                score = score + 0
            end
            love.audio.stop()
            
            map.player.sounds['correct']:play()
            game_state = "Round Over"
        else
            love.audio.stop()
    
            map.player.sounds['wrong']:play()
        end
    end
    
end

function Rapper:update()
    if self.status == 'revealed' then
        self.nameplate = self.name
    end

    if map.player.nearest_rapper == self then
        self.selected = true 
    else
        self.selected = false
    end
end

function Rapper:render()
    love.graphics.setFont(NAMEPLATE_FONT)
    love.graphics.printf(self.nameplate, self.x - 50, self.y + self.height, self.width + 100, "center")

    if self.playing then 
        love.graphics.draw(AUDIO_ICON, self.x + self.width + 10, self.y + 50, 0, 1, 1)
        love.graphics.draw(AUDIO_ICON, self.x - 10, self.y + 50, 0, -1, 1)
    end 
    
    -- determines what to draw to the screen for each rapper based on the status
    -- if the rapper is revealed their picture should show up in Audio Only mode or Normal mode
    if self.status == 'revealed' or game_mode == 'Normal' then
        if self.selected then
            love.graphics.draw(self.selected_texture, self.x, self.y, 0, 1, 1)
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

function Rapper:play_audio()
    love.audio.stop()
    self.audio[self.track_num]:play()

    -- increment track num or reset it if we just played the last track
    -- if LUA was zero indexed this would be simpler! 
    if self.track_num == self.total_verses then 
        self.track_num = 1
    else 
        self.track_num = self.track_num + 1
    end 
end

function Rapper:stop_playing()
    self.playing = false
end 

function Rapper:start_playing()
    self.playing = true
end
