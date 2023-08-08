require 'Util'
require 'Player'
require 'Animation'
require 'Rapper'
require 'Verses'

Map = Class{}

-- create the list of rapper names from the possible name list
POSSIBLE_NAME_LIST = {"RZA", "GZA", "Ghostface Killah", "Method Man", 
"Ol' Dirty Bastard", "Raekwon", "Inspectah Deck", "U-God", "Masta Killa", "Cappadonna"}

-- create the list of non Wu rappers for the possible name list
OTHER_NAME_LIST = {"David Lee Roth", "Paul Stanley"}

UPSCALE = 2.5

function Map:init()
    self.mapWidth = 48
    self.mapHeight = 27

    -- our map is slighty larger than our window size of 1280x720 to give us a little bit of map scrolling as we move around
    self.mapWidthPixels = 1500    
    self.mapHeightPixels = 800

    -- create player object
    -- reference to self means the map itself 
    self.player = Player(self)

    -- create a table to store rappers
    self.Rappers = {}
        
    self:createNameList()

    -- create rappers
    for index, name in ipairs(self.NameList) do 
        self.Rappers[index] = Rapper(self, name, index)
    end 

    self.selectedRapper = select_rapper(self)
    
    -- camera offsets
    self.camX = 0
    self.camY = 0
end

-- create a list of four rappers with no duplicates in the list
-- give a 5% chance to pick a name from the non Wu Tang list
function Map:createNameList()
    -- the list to store the names
    self.NameList = {}
    
    -- get 4 random names from the list of possible names
    for i = 1, 4 do
        -- a 1 in 30 chance to select a name from the non Wu list
        if math.random(30) == 1 then
            name = OTHER_NAME_LIST[math.random(table.getn(OTHER_NAME_LIST))]
        else
        -- get a random name from the list
            name = POSSIBLE_NAME_LIST[math.random(table.getn(POSSIBLE_NAME_LIST))]
        end

        -- for each name after the first, check for duplicates
        if i ~= 1 then 
            while name_in_list(name, self.NameList) do 
                name = POSSIBLE_NAME_LIST[math.random(table.getn(POSSIBLE_NAME_LIST))]
            end
        end 

        self.NameList[i] = name
    end
end

function Map:update(dt)
    self.camX = math.floor(
        math.max(0, 
        math.min(self.player.x - VIRTUAL_WIDTH / 2, 
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x))))

    self.camY = math.floor(
        math.max(0, 
        math.min(self.player.y - VIRTUAL_HEIGHT / 2, 
        math.min(self.mapHeightPixels - VIRTUAL_HEIGHT, self.player.y))))

    self.player:update(dt)

    for _, rapper in ipairs(self.Rappers) do 
        rapper:update(self.player.nearestRapperNumber)
    end 
end

function Map:render()
    for _, rapper in ipairs(self.Rappers) do 
        rapper:render()
    end 

    self.player:render()
end

-- randomly select one of the four options while avoiding selecting the previous rapper
function select_rapper(map)
    new_selection = map.Rappers[math.random(4)] 
    if previousRapper ~= 'none' then
        while new_selection.name == previousRapper do
            new_selection = map.Rappers[math.random(4)]
        end
    end 
    return new_selection
end 

-- returns true if the name is already in the list, takes a name and a table as arguments
function name_in_list(name, list)
    for _, list_name in ipairs(list) do 
        if list_name == name then 
            return true 
        end 
    end 
    return false
end
