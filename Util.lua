function generate_quads(atlas, tilewidth, tileheight)
    local sheetWidth = atlas:getWidth() / tilewidth
    local sheetHeight = atlas:getHeight() / tileheight

    local sheetCounter = 1
    local quads = {}

    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            quads[sheetCounter] = love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth, tileheight, atlas:getDimensions())
            sheetCounter = sheetCounter + 1
        end
    end

    return quads
end

function distance_from(x1,y1,x2,y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function color_yellow()
    love.graphics.setColor(255,255,0)
end

function color_white()
    love.graphics.setColor(255,255,255)
end

function color_lt_blue()
    love.graphics.setColor(127/255, 223/255, 255/255)
end

function make_image(filename)
    return love.graphics.newImage(filename)
end

function make_audio(filename)
    return love.audio.newSource(filename,'stream')
end
