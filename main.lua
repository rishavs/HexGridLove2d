debug = true

local inspect = require "inspect"

local hex_size = 50
local hex_grid_gap = 0
local lvl_width_hex_count = 10
local lvl_height_hex_count = 10

local hex_grid_obj = {}
-- format is

-- Sample_hex_grid_obj = { 
    -- id = {
        -- center = {x = x, y = y},
        -- color = {r, g, b},
        -- coord = {x = x, y = y, z = z}
    -- }
-- }

-- local Sample_Point = {x = 200, y = 300}
-- local Sample_Points_List = {{x = 100, y = 200}, {x = 200, y = 300}, {x = 300, y = 400}}

local test_hex_points ={}
local test_points_list = {}

function love.load(arg)
    test_hex_points = create_hex(300, 300, 100)
    xx = create_hex_grid()
end

function love.draw(dt)

    for id, hex in pairs(hex_grid_obj) do
        love.graphics.setColor(hex.color)
        love.graphics.polygon(hex.fill, hex.vertices)
        
        love.graphics.setColor(255, 255, 255)
        love.graphics.setPointSize(2)
        love.graphics.points(hex.center.x, hex.center.y)
        
        -- love.graphics.print( id, hex.center.x -20, hex.center.y -20)
        
        love.graphics.print( "x = " .. hex.coord.x, hex.center.x + hex_size/5, hex.center.y + hex_size/5)
        love.graphics.print( "y = " .. hex.coord.y, hex.center.x - hex_size/2, hex.center.y + hex_size/5)
        love.graphics.print( "z = " .. hex.coord.z, hex.center.x - hex_size/5, hex.center.y - hex_size/2)
        
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10)    
end

function love.update(dt)

end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        local cX, cY, cZ = pixel_to_hex(x, y, hex_size)
        local cSum = cX + cY + cZ
        print(cX, cY, cZ, cSum)
        print(hex_round(cX, cY, cZ))

    end
end

----------------------------------------------------------------

function create_hex_grid()
    
    local temp_hex = {}
    local temp_hex_points = {}
    local temp_hex_id = 0
    
    local hex_height = hex_size * 2
    local hex_width = (math.sqrt(3)/2) * hex_height
    
    local starting_hex_X = hex_width/2
    local starting_hex_Y = hex_height/2
    
    -- first create a staggered points grid
    for w=0, lvl_width_hex_count - 1 do
        for h = 0, lvl_height_hex_count - 1 do
            hexX = starting_hex_X + (w * hex_width) + ((hex_width/2) * (h % 2))
            hexY = starting_hex_Y + (h * hex_height * 3/4) 
            
            -- calculate and save the axial coordinates
            local cX = w - (h - (h % 2)) / 2;
            local cY = h
            local cZ = - cX - cY
            
            temp_hex_id = cX .. "x" .. cY .. "y" .. cZ .. "z";
            temp_hex_points = create_hex(hexX, hexY, hex_size - hex_grid_gap/2)
            temp_hex  = {
                center = {x = hexX, y = hexY},
                coord = {x = cX, y = cY, z = cZ},
                color = {get_random_color()},
                fill = "line",
                vertices = temp_hex_points
            }
            
            hex_grid_obj[temp_hex_id] = temp_hex
            
        end
    end
    
    -- print(inspect(hex_grid_obj))
    
end

function create_hex (hX, hY, hSize)
    local fn_hex_points = {}
    
    for i=0,5 do
        local vertAngle = 2 * math.pi / 6 * (i + 0.5)
        local vertX = hX + hSize * math.cos(vertAngle)
        local vertY = hY + hSize * math.sin(vertAngle)
        
        table.insert(fn_hex_points, vertX)
        table.insert(fn_hex_points, vertY)
    end
    
    return fn_hex_points
end

function get_random_color() 
    return math.random(50,255), math.random(50,255),  math.random(50,255)
end

function pixel_to_hex(x, y, size) 

    local fn_cX = (math.sqrt(3)/3 * x - y/3 ) / size
    local fn_cY = 2/3 * y / size
    local fn_cZ = -(math.sqrt(3)/3 * x + y/3 ) / size

    return fn_cX, fn_cY, fn_cZ

end

function pixel_to_hex2 (layout, p)
    local M = layout.orientation
    local size = layout.size
    local origin = layout.origin
    local pt = Point((p.x - origin.x) / size.x, (p.y - origin.y) / size.y)
    local q = M.b0 * pt.x + M.b1 * pt.y
    local r = M.b2 * pt.x + M.b3 * pt.y
    return Hex(q, r, -q - r)
end

function hex_round (cX_float, cY_float, cZ_float)
    local fn_cX = math.floor(math.floor (0.5 + cX_float))
    local fn_cY = math.floor(math.floor (0.5 + cY_float))
    local fn_cZ = math.floor(math.floor (0.5 + cZ_float))
    
    local cX_diff = math.abs(fn_cX - cX_float)
    local cY_diff = math.abs(fn_cY - cY_float)
    local cZ_diff = math.abs(fn_cZ - cZ_float)
    
    if cX_diff > cY_diff and cY_diff > cZ_diff then
        fn_cX = -fn_cY - fn_cZ
    else
        if cY_diff > cZ_diff then
            fn_cY = -fn_cX - fn_cZ
        else
            fn_cZ = -fn_cX - fn_cY
        end
    end
    return fn_cX, fn_cY, fn_cZ
end