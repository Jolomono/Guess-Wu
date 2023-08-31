require 'util'
require 'player'
require 'animation'
require 'rapper'
require 'verses'

Map = Class{}

-- create the list of rapper names from the possible name list
POSSIBLE_NAME_LIST = {"RZA", "GZA", "Ghostface Killah", "Method Man", 
"Ol' Dirty Bastard", "Raekwon", "Inspectah Deck", "U-God", "Masta Killa", "Cappadonna"}

-- create the list of non Wu rappers for the possible name list
OTHER_NAME_LIST = {"David Lee Roth", "Paul Stanley"}

function Map:init()
    -- map is slightly larger than window size of 1280x720 to allow a little bit of map scrolling as we move
    self.width = 1500
    self.height = 800

    -- create player object
    -- reference to self means the map itself
    self.player = Player(self)

    -- create a table to store rappers
    self.rappers = {}

    self.frozen = false

    -- pick a random set of rappers from both name lists
    local name_list = create_name_list()

    -- create a table of rappers using the name_list
    for index, name in ipairs(name_list) do
        self.rappers[index] = Rapper(self, name, index)
    end

    -- pick a rapper for the round 
    self.selected_rapper = self:select_rapper()

    -- camera offsets
    self.cam_x = 0
    self.cam_y = 0
end

function Map:update(dt)
    self.cam_x = math.floor(
        math.max(0,
        math.min(self.player.x - VIRTUAL_WIDTH / 2,
        math.min(self.width - VIRTUAL_WIDTH, self.player.x))))

    self.cam_y = math.floor(
        math.max(0,
        math.min(self.player.y - VIRTUAL_HEIGHT / 2,
        math.min(self.height - VIRTUAL_HEIGHT, self.player.y))))

    if self.frozen == false then
        self.player:update(dt)
    end

    for _, rapper in ipairs(self.rappers) do
        rapper:update()
    end
end

function Map:render()
    for _, rapper in ipairs(self.rappers) do
        rapper:render()
    end

    self.player:render()
end

-- create a list of four rappers with no duplicates in the list
-- give a 1/30 chance to pick a name from the non Wu Tang list
function create_name_list()
    -- the list to store the names
    local list = {}
    local list_name = nil 

    -- get 4 random names from the list of possible names
    for i = 1, 4 do
        -- a 1 in 30 chance to select a name from the non Wu list
        if math.random(30) == 1 then
            list_name = OTHER_NAME_LIST[math.random(table.getn(OTHER_NAME_LIST))]
        else
        -- get a random name from the Wu Tang list
            list_name = POSSIBLE_NAME_LIST[math.random(table.getn(POSSIBLE_NAME_LIST))]
        end

        -- for each name after the first, check for duplicates
        if i ~= 1 then
            while name_in_list(list_name, list) do
                list_name = POSSIBLE_NAME_LIST[math.random(table.getn(POSSIBLE_NAME_LIST))]
            end
        end

        list[i] = list_name
    end

    return list 
end

-- randomly select one of the four options while avoiding selecting the previous rapper
function Map:select_rapper()
    local new_selection = self.rappers[math.random(4)]
    while new_selection.name == previous_rapper do
        new_selection = self.rappers[math.random(4)]
    end
    return new_selection
end

-- returns true if the name is already in the list, takes a name and a table (list) as arguments
function name_in_list(name, list)
    for _, list_name in ipairs(list) do
        if list_name == name then
            return true
        end
    end
    return false
end
