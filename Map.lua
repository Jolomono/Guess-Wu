require 'Util'
require 'Player'
require 'Animation'
require 'Rapper'
require 'Verses'

Map = Class{}

UPSCALE = 2.5

TILE_BRICK = 1
TILE_EMPTY = 4

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

-- flag sprites
POLE_TOP = 8
POLE_MIDDLE = 12
POLE_BOTTOM = 16

FLAG_WAVE_1 = 13
FLAG_WAVE_2 = 14
FLAG_DOWN = 15

function Map:init()
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    
    self.music = love.audio.newSource('sounds/music.wav', 'static')
    
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 48
    self.mapHeight = 27
    self.tiles = {}

    -- our map is slighty larger than our window size of 1280x720 to give us a little bit of map scrolling as we move around
    self.mapWidthPixels = 1500    
    self.mapHeightPixels = 800

    -- create player object
    -- reference to self means the map itself 
    self.player = Player(self)

    -- create a table to store rappers
    self.Rappers = {}

    -- create the list of rapper names from the possible name list
    self.possibleNameList = {"RZA", "GZA", "Ghostface Killah", "Method Man", 
        "Ol' Dirty Bastard", "Raekwon", "Inspectah Deck", "U-God", "Masta Killa", "Cappadonna"}

    -- create the list of non Wu rappers for the possible name list
    self.otherNameList = {"David Lee Roth", "Paul Stanley"}
        
    self:createNameList()

    -- create rappers
    self.rapper1 = Rapper(self, self.NameList[1], 1)
    self.rapper2 = Rapper(self, self.NameList[2], 2)
    self.rapper3 = Rapper(self, self.NameList[3], 3)
    self.rapper4 = Rapper(self, self.NameList[4], 4)

    self.Rappers[1] = self.rapper1
    self.Rappers[2] = self.rapper2
    self.Rappers[3] = self.rapper3
    self.Rappers[4] = self.rapper4
    
    -- randomly select one of the four options
    self.newSelection = self.Rappers[math.random(4)]

    -- checks the new selection to make sure it doesn't match the previous selection
    -- if this is the first time and previousRapper is 'none' then skips this check
    if previousRapper ~= 'none' then
        while self.newSelection.name == previousRapper do
            self.newSelection = self.Rappers[math.random(4)]
        end
    end

    -- sets the newSelection as the selectedRapper
    self.selectedRapper = self.newSelection
    
    -- camera offsets
    self.camX = 0
    self.camY = 0

    -- generate a quad (individual frame/sprite) for each tile
    self.tileSprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)

    --[[ filling the map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            
           -- support for multiple sheets per tile; storing tiles as tables
            self:setTile(x, y, TILE_EMPTY)
        end
    end
    ]]

    -- begin generating the terrain using vertical scan lines
    
    local x = 1
    while x < self.mapWidth do
        -- make sure we're 2 tiles from the edge at least 
        local bushStart
        if x < self.mapWidth - 2 then
            if math.random(2) == 1 then
                -- chose a random vertical spot
                if (x % 2) == 0 then
                    -- top half of map
                    bushStart = math.random(self.mapHeight / 2)
                else
                    -- bottom half of map
                    bushStart = math.random(self.mapHeight / 2, self.mapHeight)
                end

                self:setTile(x, bushStart, BUSH_LEFT)
                self:setTile(x + 1, bushStart, BUSH_RIGHT)
            end
        end 
    x = x + 1
            
    end
    -- start the background music
    self.music:setLooping(true)
    self.music:setVolume(0.25)
    --self.music:play() 
end

-- create a list of four rappers with no duplicates in the list
-- give a 5% chance to pick a name from the non Wu Tang list
function Map:createNameList()
    -- the list to store the names
    self.NameList = {}
    
    -- get 4 random names from the list of possible names
    for i = 1, 4 do
        -- a 5% chance to select a name from the non Wu list
        if math.random(30) == 1 then
            name = self.otherNameList[math.random(table.getn(self.otherNameList))]
        else
        -- get a random name from the list
            name = self.possibleNameList[math.random(table.getn(self.possibleNameList))]
        end

        -- if that name is already on the list, get a new name
        while name == self.NameList[1] or
            name == self.NameList[2] or
            name == self.NameList[3] or
            name == self.NameList[4] do
            name = self.possibleNameList[math.random(table.getn(self.possibleNameList))]
        end

        -- add that name to  the list
        self.NameList[i] = name
    end
end

-- tiles is a 1d array of values that will determine what to print to the screen. 
-- subtracting 1 from y will get the 0 indexed y value for the first row
-- multiplying the y value by the width of the map will go to the end of the row so that adding x will start on 
-- the correct "row" in the 1d array
function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end

-- this method will get the integer value of a specific tile in the 1d tiles array
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, 
                    math.floor(y / self.tileHeight) + 1)
    }
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
    self.rapper1:update(self.player.nearestRapperNumber)
    self.rapper2:update(self.player.nearestRapperNumber)
    self.rapper3:update(self.player.nearestRapperNumber)
    self.rapper4:update(self.player.nearestRapperNumber)
end

function Map:render()
    --[[for y = 1, self.mapHeight do
        for x = 1, self.mapWidth  do
            love.graphics.draw(self.spritesheet, self.tileSprites[self:getTile(x, y)], 
                (x - 1) * self.tileWidth * UPSCALE, (y - 1) * self.tileHeight * UPSCALE, 0, UPSCALE, UPSCALE)
        end
    end
    ]]
    
    self.rapper1:render()
    self.rapper2:render()
    self.rapper3:render()
    self.rapper4:render() 
    
    self.player:render()
end