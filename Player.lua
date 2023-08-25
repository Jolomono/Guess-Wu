Player = Class{}

require 'Animation'
require 'Util'

local MOVE_SPEED = 600
local PLAYER_UPSCALE = 3
local HITBOX_X_OFFSET = 14
local HITBOX_Y_OFFSET = 18

function Player:init(map)
    self.map = map
    
    self.width = 16
    self.height = 20

    self.x = map.mapWidthPixels / 2
    self.y = map.mapHeightPixels / 2 - self.height

    self.dx = 0
    self.dy = 0

    self.nearestRapper = nil

    self.currently_playing = nil 

    self.currentTrack = nil

    self.attempts = 1

    -- sound effects
    self.sounds = {
        ['correct'] = love.audio.newSource('sounds/correct.mp3', 'static'),
        ['wrong'] = love.audio.newSource('sounds/wrong.wav', 'static')
    }

    self.texture = make_image('graphics/blue_alien.png')
    self.frames = generateQuads(self.texture, 16, 20)

    self.victory = false
    
    self.state = 'idle'
    self.direction = 'right'

    self.animations = {
        ['idle'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[1]
            },
            interval = 1
        },
        ['walking'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[9], self.frames[10], self.frames[11]
            },
            interval = 0.15
        }
    }

    self.animation = self.animations['idle']

    self.behaviors = {
        ['idle'] = function()
            -- play audio
            if love.keyboard.wasPressed('space') then
                self:playAudio(self.nearestRapper)
                self:set_currently_playing(self.nearestRapper)
            end 
            
            -- if any movement key is pressed, start moving
            for _, key in ipairs({'a', 's', 'd', 'w'}) do 
                if love.keyboard.wasPressed(key) then 
                    self.state = 'walking'
                    self.animations['walking']:restart()
                    self.animation = self.animations['walking']
                end 
            end
        end, 
        ['walking'] = function()
            if love.keyboard.wasPressed('space') then
                self:playAudio(self.nearestRapper)
                self:set_currently_playing(self.nearestRapper)
            -- move up/left 
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('a') then
                self:moveUp()
                self:moveLeft()
            -- move up/right
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('d') then
                self:moveUp()
                self:moveRight()
            -- move down/left
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('a') then
                self:moveDown()
                self:moveLeft()
            -- move down/right
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('d') then
                self:moveDown()
                self:moveRight()
            elseif love.keyboard.isDown('a') then
                self:moveLeft()
            elseif love.keyboard.isDown('d') then
                self:moveRight()
            elseif love.keyboard.isDown('w') then
                self:moveUp()
            elseif love.keyboard.isDown('s') then
                self:moveDown()
            else
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.dx = 0
                self.dy = 0
            end 
        end
    }
end

function Player:moveUp()
    self.dy = -MOVE_SPEED
end 

function Player:moveDown()
    self.dy = MOVE_SPEED
end 

function Player:moveRight()
    self.dx = MOVE_SPEED
    self.direction = 'right'
end 

function Player:moveLeft()
    self.dx = -MOVE_SPEED
    self.direction = 'left'
end 

function Player:getNearestCollisionCoords()
    rapperL = self.nearestRapper.x - HITBOX_X_OFFSET
    rapperR = self.nearestRapper.x + self.nearestRapper.width + HITBOX_X_OFFSET
    rapperTop = self.nearestRapper.y - HITBOX_Y_OFFSET
    rapperBot = self.nearestRapper.y + self.nearestRapper.height + HITBOX_Y_OFFSET
end

function Player:rapperCollision(x, y)
    self:getNearestCollisionCoords()
    return  x < rapperR and 
            x + self.width > rapperL and 
            y < rapperBot and 
            y + self.height > rapperTop
end

function Player:wallCollision(x, y)
    return  x < HITBOX_X_OFFSET or
            x + self.width > self.map.mapWidthPixels - HITBOX_X_OFFSET or 
            y < HITBOX_Y_OFFSET or 
            y + self.height > self.map.mapHeightPixels - HITBOX_Y_OFFSET
end

function Player:collision(x, y)
    return self:wallCollision(x, y) or self:rapperCollision(x, y)
end

function Player:move(dt)
    old_x = self.x 
    old_y = self.y 
    new_x = self.x + self.dx * dt
    new_y = self.y + self.dy * dt

    -- is there a collision? 
    if self:collision(new_x, new_y) then
        -- if we collided with a rapper, touch them
        if self:rapperCollision(new_x, new_y) then self:touchRapper() end
        
        self.x, self.y = self:get_available_position(old_x, old_y, new_x, new_y)
    -- no collision, move to new spot
    else
        self.x, self.y = new_x, new_y 
    end 
end

-- if we can move our position horizontally or vertically only without a collision, return that position
--  otherwise return the old position
function Player:get_available_position(old_x, old_y, new_x, new_y)
    if self:collision(old_x, new_y) == false then 
        return old_x, new_y
    elseif self:collision(new_x, old_y) == false then 
        return new_x, old_y
    else 
        return old_x, old_y 
    end 
end 

function Player:touchRapper()
    if self.nearestRapper.status == 'hidden' then
        self.nearestRapper:touched(self.attempts)
        self.attempts = self.attempts + 1
    end
end

-- returns the number of nearest rapper to the player
-- updated to return the Rapper Object itself
function Player:findNearestRapper()
    local nearestRapper = nil
    local distance = nil
    for i = 1, table.getn(self.map.Rappers) do
        local current_distance = distanceFrom(self.x, self.y, self.map.Rappers[i].middlex, self.map.Rappers[i].middley)
        if distance == nil then
            distance = current_distance
            nearestRapper = self.map.Rappers[i]
        elseif current_distance < distance then
            distance = current_distance
            nearestRapper = self.map.Rappers[i]
        end
    end
    return nearestRapper
end

-- plays an audio track corresponding to the nearest rapper
-- will not play the last track played (or currently playing track)
function Player:playAudio(rapper)
    love.audio.stop()
    newTrack = rapper.audio[math.random(rapper.total_verses)]
    while newTrack == self.currentTrack do
        newTrack = rapper.audio[math.random(rapper.total_verses)]
    end
    self.currentTrack = newTrack
    self.currentTrack:play()
end

function Player:update(dt)
    self.nearestRapper = self:findNearestRapper()
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self:move(dt)
end

function Player:render()
    if self.direction == 'right' then
        scaleX = 1 * PLAYER_UPSCALE
    else
        scaleX = -1 * PLAYER_UPSCALE
    end

    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), 
        math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
        0, scaleX, PLAYER_UPSCALE,
        -- origin point for sprite
        self.width / 2, self.height / 2)
end

-- calls rapper:stop_playing on whichever is currently playing
-- updates the currently playing rapper
-- this updates the rapper 'playing' status to show or not show the now playing icon
function Player:set_currently_playing(rapper)
    if self.currently_playing ~= nil then
        self.currently_playing:stop_playing()
    end 
    self.currently_playing = rapper 
    rapper:start_playing()
end
