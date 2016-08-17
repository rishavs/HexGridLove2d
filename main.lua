debug = true

local inspect = require "inspect"

local hex_size = 50
local hex_grid_gap = 5
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
        love.graphics.polygon("line", hex.vertices)
        
        love.graphics.setColor(255, 255, 255)
        love.graphics.setPointSize(3)
        love.graphics.points(hex.center.x, hex.center.y)
    end

end

function love.update(dt)

end

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
            hexX = starting_hex_X + (w * hex_width) + (((hex_width/2) + hex_grid_gap/2) * (h % 2)) + w * hex_grid_gap
            hexY = starting_hex_Y + (h * hex_height * 3/4) + hex_grid_gap/2 + h * hex_grid_gap
            
            -- calculate and save the axial coordinates
            local cX = h - (w - h) / 2;
            local cZ = w;
            local cY = -1*(cX+cZ);
            
            temp_hex_id = cX .. "x" .. cY .. "y" .. cZ .. "z";
            temp_hex_points = create_hex(hexX, hexY, hex_size)
            temp_hex  = {
                center = {x = hexX, y = hexY},
                coord = {x = cX, y = cY, z = cZ},
                color = {get_random_color()},
                vertices = temp_hex_points
            }
            
            hex_grid_obj[temp_hex_id] = temp_hex
            
        end
    end
    
    print(inspect(hex_grid_obj))
    
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