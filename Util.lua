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

-- makes a table of audio files provided that the audio files are numbered in the range 1 to total_tracks in the folder "path"
function make_audio_table(path, total_tracks)
    local audio_table = {}
    for i = 1, total_tracks do 
        local full_path = string.format("%s%s.mp3", path, i)
        table.insert(audio_table, make_audio(full_path))
    end 
    return audio_table
end

-- shuffles a table argument, this is a destructive action, the original table order is not preserved
function shuffle_table(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end
