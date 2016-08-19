debug = true

local inspect = require "inspect"

local hex_size = 100
local hex_grid_gap = 10
local lvl_width_hex_count = 10
local lvl_height_hex_count = 10

local mousex, mousey 
local hex_grid_obj = {}
local points_list = {}

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
        
        love.graphics.print( "x = " .. hex.coord.q, hex.center.x + hex_size/4, hex.center.y + hex_size/4)
        love.graphics.print( "y = " .. hex.coord.r, hex.center.x - hex_size/2, hex.center.y + hex_size/4)
        love.graphics.print( "z = " .. hex.coord.s, hex.center.x - hex_size/4, hex.center.y - hex_size/2)
        
    end
    
    if #points_list > 0 then
        love.graphics.points(points_list)
    end
    
    if #points_list > 2 then
        love.graphics.line(points_list)
    end
    
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10)    
    
    local cQ, cR, cS = pixel_to_hex(mousex, mousey, hex_size)
    love.graphics.print("id: ".. cQ .. "x" .. cR .. "y" .. cS .. "z", 10, 20)    
    
    love.graphics.print(cQ .. "x" .. cR .. "y" .. cS .. "z", mousex -30, mousey -50)    
    
    love.graphics.setColor(100, 255, 100)
    love.graphics.print(mousex .. ", " .. mousey, mousex -30, mousey -30)
end

function love.update(dt)
    mousex, mousey = love.mouse.getPosition()
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
    
        table.insert(points_list, x)
        table.insert(points_list, y)
    
        local cQ, cR, cS = pixel_to_hex(x, y, hex_size)
        local cSum = cQ + cR + cS
        print("\nMouse click at: " .. x .. ", " .. y)
        print(cQ, cR, cS, cSum)

    end
end

----------------------------------------------------------------

function create_hex_grid()
    
    local temp_hex = {}
    local temp_hex_points = {}
    local temp_hex_id = 0
    
    local hex_height = hex_size * 2
    local hex_width = math.sqrt(3) * hex_size
    
    local starting_hex_X = hex_width/2
    local starting_hex_Y = hex_height/2
    
    -- first create a staggered points grid
    for w=0, lvl_width_hex_count - 1 do
        for h = 0, lvl_height_hex_count - 1 do
            hexX = starting_hex_X + (w * hex_width) + ((hex_width/2) * (h % 2))
            hexY = starting_hex_Y + (h * hex_height * 3/4) 
            
            -- calculate and save the axial coordinates
            local cQ = w - (h - (h % 2)) / 2
            local cR = h
            local cS = - cQ - cR
            
            if cQ == -0 then cQ = 0 end
            if cR == -0 then cR = 0 end
            if cS == -0 then cS = 0 end
    
    
            temp_hex_id = cQ .. "x" .. cR .. "y" .. cS .. "z"
            temp_hex_points = create_hex(hexX, hexY, hex_size - hex_grid_gap/2)
            temp_hex  = {
                center = {x = hexX, y = hexY},
                coord = {q = cQ, r = cR, s = cS},
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

function pixel_to_hex(x, y) 
    rx = x - math.sqrt(3) * hex_size/2
    ry = y - hex_size
    
    local cQ_float = (rx * math.sqrt(3)/3 - ry / 3) / hex_size 
    local cR_float =  ry * 2/3 / hex_size 
    local cS_float = -cQ_float - cR_float
    
    -- return cQ_float, cR_float, cS_float
    local cQ, cR, cS = get_round_hex_coord( cQ_float, cR_float, cS_float)
    return  cQ, cR, cS
end

-- Round to the nearest hex
function get_round_hex_coord(cX_float, cY_float, cZ_float)

    local fn_cX = round(cX_float)    
    local fn_cY = round(cY_float)
    local fn_cZ = round(cZ_float)
    
    local cX_diff = math.abs(fn_cX - cX_float)
    local cY_diff = math.abs(fn_cY - cY_float)
    local cZ_diff = math.abs(fn_cZ - cZ_float)
    
    if cX_diff > cY_diff and cX_diff > cZ_diff then
        fn_cX = -fn_cY - fn_cZ
    elseif cY_diff > cZ_diff then
        fn_cY = -fn_cX - fn_cZ
    else
        fn_cZ = -fn_cX - fn_cY
    end
    
    if fn_cX == -0 then fn_cX = 0 end
    if fn_cY == -0 then fn_cY = 0 end
    if fn_cZ == -0 then fn_cZ = 0 end
    
    return fn_cX, fn_cY, fn_cZ
end



function round(num, dp)
  local mult = 10^(dp or 0)
  return (math.floor(num * mult + 0.5)) / mult
end
