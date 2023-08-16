Player = Class{}

require 'Animation'
require 'Util'

local MOVE_SPEED = 600

local PLAYER_UPSCALE = 2.8
local HITBOX_X_OFFSET = 16
local HITBOX_Y_OFFSET = 18

function Player:init(map)
    self.map = map
    
    self.width = 16
    self.height = 20

    self.x = map.mapWidthPixels / 2
    self.y = map.mapHeightPixels / 2 - self.height

    self.dx = 0
    self.dy = 0

    self.nearestRapperNumber = 1

    self.currentTrack = nil

    self.attempts = 1

    -- sound effects
    self.sounds = {
        ['correct'] = love.audio.newSource('sounds/correct.mp3', 'static'),
        ['wrong'] = love.audio.newSource('sounds/wrong.wav', 'static')
    }

    self.texture = love.graphics.newImage('graphics/blue_alien.png')
    self.frames = generateQuads(self.texture, 16, 20)

    self.victory = false
    
    self.state = 'idle'
    self.direction = 'right'

    self.collided = "false"

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
            if love.keyboard.wasPressed('space') then
                self:playAudio(self.nearestRapperNumber)
            -- move up/left 
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('a') then
                self.dx = -MOVE_SPEED
                self.dy = -MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
                self.direction = 'left'
            -- move up/right
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('d') then
                self.dx = MOVE_SPEED
                self.dy = -MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
                self.direction = 'right'
            -- move down/left
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('a') then
                self.dx = -MOVE_SPEED
                self.dy = MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
                self.direction = 'left'
            -- move down/right
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('d') then
                self.dx = MOVE_SPEED
                self.dy = MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
                self.direction = 'right'
            elseif love.keyboard.isDown('a') then
                self.dx = -MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
                self.direction = 'left'
            elseif love.keyboard.isDown('d') then
                self.dx = MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
                self.direction = 'right'
            elseif love.keyboard.isDown('w') then
                self.dy = -MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            elseif love.keyboard.isDown('s') then
                self.dy = MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            else
                self.dx = 0
                self.dy = 0
            end
        end, 
        ['walking'] = function()
            if love.keyboard.wasPressed('space') then
                self:playAudio(self.nearestRapperNumber)
            -- move up/left 
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('a') then
                self.dx = -MOVE_SPEED
                self.dy = -MOVE_SPEED
                self.direction = 'left'
            -- move up/right
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('d') then
                self.dx = MOVE_SPEED
                self.dy = -MOVE_SPEED
                self.direction = 'right'
            -- move down/left
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('a') then
                self.dx = -MOVE_SPEED
                self.dy = MOVE_SPEED
                self.direction = 'left'
            -- move down/right
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('d') then
                self.dx = MOVE_SPEED
                self.dy = MOVE_SPEED
                self.direction = 'right'
            elseif love.keyboard.isDown('a') then
                self.dx = -MOVE_SPEED
                self.direction = 'left'
            elseif love.keyboard.isDown('d') then
                self.dx = MOVE_SPEED
                self.direction = 'right'
            elseif love.keyboard.isDown('w') then
                self.dy = -MOVE_SPEED
            elseif love.keyboard.isDown('s') then
                self.dy = MOVE_SPEED
            else
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.dx = 0
                self.dy = 0
            end 

            -- collision coordinates
            self:getNearestCollisionCoords()
            
            -- if we're moving right
            if self.dx > 0  and self.dy == 0 then
                self:checkRightCollision()
            -- if we're moving left
            elseif self.dx < 0 and self.dy == 0 then
                self:checkLeftCollision()
            -- if we're moving up
            elseif self.dx == 0 and self.dy < 0 then
                self:checkUpCollision()
            -- if we're moving down
            elseif self.dx == 0 and self.dy > 0 then
                self:checkDownCollision()      
            -- if we're moving up/right
            elseif self.dx > 0 and self.dy < 0 then
                self:checkUpCollision()
                self:checkRightCollision()
            -- if we're moving down/right
            elseif self.dx > 0 and self.dy > 0 then
                self:checkDownCollision()
                self:checkRightCollision()
            -- if we're moving up/left
            elseif self.dx < 0 and self.dy < 0 then
                self:checkUpCollision()
                self:checkLeftCollision()
            -- if we're moving down/left
            elseif self.dx < 0 and self.dy > 0 then
                self:checkDownCollision()
                self:checkLeftCollision()
            end
        end
    }
end

function Player:getNearestCollisionCoords()
    rapperL = self.map.Rappers[self.nearestRapperNumber].x - HITBOX_X_OFFSET
    rapperR = self.map.Rappers[self.nearestRapperNumber].x + self.map.Rappers[self.nearestRapperNumber].width + HITBOX_X_OFFSET
    rapperTop = self.map.Rappers[self.nearestRapperNumber].y - HITBOX_Y_OFFSET
    rapperBot = self.map.Rappers[self.nearestRapperNumber].y + self.map.Rappers[self.nearestRapperNumber].height + HITBOX_Y_OFFSET
end

-- returns true if we've hit a rapper, false otherwise
function Player:rapperCollision()
    if self.x > rapperR or 
        self.x + self.width < rapperL then
            return false
    end
    
    if self.y > rapperBot or 
        self.y + self.height < rapperTop then
            return false
    end

    -- if this is the first time we've touched a rapper then reveal it
    if self.map.Rappers[self.nearestRapperNumber].status == 'hidden' then
        self.map.Rappers[self.nearestRapperNumber]:touched(self.attempts)
        self.attempts = self.attempts + 1
    end

    -- if neither of these returns false then there is a collision
    return true
end

-- checks to make sure we haven't passed left boundary of map then
-- checks two tiles to our left to see if a collision occurred
function Player:checkLeftCollision()
    self:rapperCollision()
    
    if self.x <= HITBOX_X_OFFSET then
        self.x = HITBOX_X_OFFSET
        self.dx = 0
    end

    -- if we've collided with a rapper while moving left then put the player on the right edge of that rapper
    if self.x + self.width > rapperL and self.x <= rapperR and self.y + self.height > rapperTop and self.y < rapperBot then                 
        -- if so, reset velocity and position and change state
            self.x = rapperR
            self.dx = 0
    end
    
end

-- checks to make sure we haven't passed right boundary of map then
-- check two tiles to our right to see if a collision occured
function Player:checkRightCollision()
    self:rapperCollision()

    if self.x + self.width >= self.map.mapWidthPixels - HITBOX_X_OFFSET then
        self.x = self.map.mapWidthPixels - self.width - HITBOX_X_OFFSET
        self.dx = 0
    end
    
    -- if we've collided with a rapper while moving right then put the player on the left edge of that rapper
    if self.x + self.width >= rapperL and self.x < rapperR and self.y + self.height > rapperTop and self.y < rapperBot then 
        -- if so, reset velocity and position and change state
        self.x = rapperL - self.width
        self.dx = 0
    end
end

-- check for collisions above the player
function Player:checkUpCollision()
    self:rapperCollision()

    if self.y <= HITBOX_Y_OFFSET then
        self.y = HITBOX_Y_OFFSET
        self.dy = 0
    end

    -- if we collide with a rapper while moving up, place the player on the bottom edge of that rapper
    if self.y <= rapperBot and self.y + self.height > rapperTop and self.x < rapperR and self.x + self.width > rapperL then
        self.y = rapperBot
        self.dy = 0
    end
end

-- check for collisions below the player
function Player:checkDownCollision()
    self:rapperCollision()

    if self.y + self.height >= self.map.mapHeightPixels - HITBOX_Y_OFFSET then
        self.y = self.map.mapHeightPixels - self.height - HITBOX_X_OFFSET
        self.dy = 0
    end
    
    -- if we collide with a rapper while moving down, place the player on the top edge of that rapper
    if self.y < rapperBot and self.y + self.height >= rapperTop and self.x < rapperR and self.x + self.width > rapperL then
        self.y = rapperTop - self.height
        self.dy = 0
    end
end

-- returns the number of nearest rapper to the player
function Player:nearestRapper()
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
    return nearestRapper.number
end

-- plays an audio track corresponding to the nearest rapper
-- will not play the last track played (or currently playing track)
function Player:playAudio(rapper)
    love.audio.stop()
    newTrack = map.Rappers[rapper].audio[math.random(map.Rappers[rapper].total_verses)]
    while newTrack == self.currentTrack do
        newTrack = map.Rappers[rapper].audio[math.random(map.Rappers[rapper].total_verses)]
    end
    self.currentTrack = newTrack
    self.currentTrack:play()
end

function Player:update(dt)
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    self.nearestRapperNumber = self:nearestRapper()
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
