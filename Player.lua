Player = Class{}

require 'animation'
require 'util'

local MOVE_SPEED = 600
local PLAYER_UPSCALE = 3
local HITBOX_X_OFFSET = 14
local HITBOX_Y_OFFSET = 18

function Player:init(map)
    self.map = map
    
    self.width = 16
    self.height = 20

    self.x = map.width / 2
    self.y = map.height / 2 - self.height

    self.dx = 0
    self.dy = 0

    self.nearest_rapper = nil

    self.currently_playing = nil

    self.attempts = 1

    -- sound effects
    self.sounds = {
        ['correct'] = love.audio.newSource('sounds/correct.mp3', 'static'),
        ['wrong'] = love.audio.newSource('sounds/wrong.wav', 'static')
    }

    self.texture = make_image('graphics/blue_alien.png')
    self.frames = generate_quads(self.texture, 16, 20)

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
                self.nearest_rapper:play_audio()
                self:set_currently_playing(self.nearest_rapper)
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
                self.nearest_rapper:play_audio()
                self:set_currently_playing(self.nearest_rapper)
            -- move up/left 
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('a') then
                self:move_up()
                self:move_left()
            -- move up/right
            elseif love.keyboard.isDown('w') and love.keyboard.isDown('d') then
                self:move_up()
                self:move_right()
            -- move down/left
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('a') then
                self:move_down()
                self:move_left()
            -- move down/right
            elseif love.keyboard.isDown('s') and love.keyboard.isDown('d') then
                self:move_down()
                self:move_right()
            elseif love.keyboard.isDown('a') then
                self:move_left()
            elseif love.keyboard.isDown('d') then
                self:move_right()
            elseif love.keyboard.isDown('w') then
                self:move_up()
            elseif love.keyboard.isDown('s') then
                self:move_down()
            else
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.dx = 0
                self.dy = 0
            end 
        end
    }
end

function Player:move_up()
    self.dy = -MOVE_SPEED
end 

function Player:move_down()
    self.dy = MOVE_SPEED
end 

function Player:move_right()
    self.dx = MOVE_SPEED
    self.direction = 'right'
end 

function Player:move_left()
    self.dx = -MOVE_SPEED
    self.direction = 'left'
end 

function Player:rapper_collision(x, y, rapper)
    local rapper_left_edge = rapper.left_edge - HITBOX_X_OFFSET
    local rapper_right_edge = rapper.right_edge + HITBOX_X_OFFSET
    local rapper_top_edge = rapper.top_edge - HITBOX_Y_OFFSET
    local rapper_bottom_edge = rapper.bottom_edge + HITBOX_Y_OFFSET
    return  x < rapper_right_edge and 
            x + self.width > rapper_left_edge and 
            y < rapper_bottom_edge and 
            y + self.height > rapper_top_edge
end

function Player:wall_collision(x, y)
    return  x < HITBOX_X_OFFSET or
            x + self.width > self.map.width - HITBOX_X_OFFSET or 
            y < HITBOX_Y_OFFSET or 
            y + self.height > self.map.height - HITBOX_Y_OFFSET
end

function Player:collision(x, y)
    return self:wall_collision(x, y) or self:rapper_collision(x, y, self.nearest_rapper)
end

function Player:move(dt)
    local old_x = self.x 
    local old_y = self.y
    local new_x = self.x + self.dx * dt
    local new_y = self.y + self.dy * dt

    -- is there a collision? 
    if self:collision(new_x, new_y) then
        -- if we collided with a rapper, touch them
        if self:rapper_collision(new_x, new_y, self.nearest_rapper) then self:touch_rapper() end
        
        -- move to an available position
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

-- if this is the first time we've touched this rapper then reveal them and increment attempts by 1
function Player:touch_rapper()
    if self.nearest_rapper.status == 'hidden' then
        self.nearest_rapper:touched(self.attempts)
        self.attempts = self.attempts + 1
    end
end

-- returns the nearest Rapper object
function Player:find_nearest_rapper()
    local nearest_rapper = nil
    local distance = nil
    for i = 1, table.getn(self.map.rappers) do
        local current_distance = distance_from(self.x, self.y, self.map.rappers[i].middlex, self.map.rappers[i].middley)
        if distance == nil then
            distance = current_distance
            nearest_rapper = self.map.rappers[i]
        elseif current_distance < distance then
            distance = current_distance
            nearest_rapper = self.map.rappers[i]
        end
    end
    return nearest_rapper
end

function Player:update(dt)
    self.nearest_rapper = self:find_nearest_rapper()
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self:move(dt)
end

function Player:render()
    local scale_x = nil 
    if self.direction == 'right' then
        scale_x = 1 * PLAYER_UPSCALE
    else
        scale_x = -1 * PLAYER_UPSCALE
    end

    love.graphics.draw(self.texture, self.animation:getCurrentFrame(), 
        math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
        0, scale_x, PLAYER_UPSCALE,
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
