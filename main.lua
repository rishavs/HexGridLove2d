debug = true

local inspect = require "inspect"

local hex_size = 10
local hex_grid_gap = 1
local lvl_width_hex_count = 40
local lvl_height_hex_count = 40

local mousex, mousey 
local hex_grid_obj = {}
local points_list = {}

local test_hex_points ={}
local test_points_list = {}

function love.load(arg)
    test_hex_points = create_hex(300, 300, 100)
    
    -- First create the hex grid
    create_hex_grid()
    
    -- Add neighbour information to each hex in grid
    -- now make all the edge hexes as water
end

function love.draw(dt)

    for id, hex in pairs(hex_grid_obj) do
        love.graphics.setColor(50, 50, 50)
        love.graphics.polygon("line", hex.vertices)
        
        -- love.graphics.setColor(255, 255, 255)
        -- love.graphics.print( "x = " .. hex.coord.q, hex.center.x + hex_size/4, hex.center.y + hex_size/4)
        -- love.graphics.print( "y = " .. hex.coord.r, hex.center.x - hex_size/2, hex.center.y + hex_size/4)
        -- love.graphics.print( "z = " .. hex.coord.s, hex.center.x - hex_size/4, hex.center.y - hex_size/2)
        
    end

    -- love.graphics.print( id, hex.center.x -20, hex.center.y -20)
    

    
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10)    

end

function love.update(dt)
    mousex, mousey = love.mouse.getPosition()
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
    
        table.insert(points_list, x)
        table.insert(points_list, y)
    
        local h_id = get_hex_id_from_point(x, y)
        if h_id then
            local cQ, cR, cS = h_id.q, h_id.r, h_id.s
            local cSum = cQ + cR + cS
            print("\nMouse click at: " .. x .. ", " .. y)
            print("Hex Id is : " .. cQ .. "q " .. cR .. "r " .. cS .. "s and Sum = " .. cSum)
            
            local h_id = cQ .. "q" .. cR .. "r" .. cS .. "s"
            local nbr = get_hex_neighbour(h_id)
            print("Is Hex on the Edge? : ", hex_grid_obj[h_id].isOnEdge)
            print("its neighbours are : \n" .. inspect(nbr))
        end
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
    
    
            temp_hex_id = cQ .. "q" .. cR .. "r" .. cS .. "s"
            temp_hex_points = create_hex(hexX, hexY, hex_size - hex_grid_gap/2)
            temp_hex  = {
                center = {x = hexX, y = hexY},
                coord = {q = cQ, r = cR, s = cS},
                hexType = "empty",
                isOnEdge = false,
                vertices = temp_hex_points
            }
            
            -- mark the edge hexagons
            if w == 0 or h == 0 or w == (lvl_width_hex_count - 1) or h ==  (lvl_height_hex_count - 1) then
                temp_hex.isOnEdge = true
            end
            
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

function get_hex_id_from_point(x, y) 
    rx = x - math.sqrt(3) * hex_size/2
    ry = y - hex_size
    
    local cQ_float = (rx * math.sqrt(3)/3 - ry / 3) / hex_size 
    local cR_float =  ry * 2/3 / hex_size 
    local cS_float = -cQ_float - cR_float
    
    -- return cQ_float, cR_float, cS_float
    local cQ, cR, cS = get_round_hex_coord( cQ_float, cR_float, cS_float)
    
    -- check if hex exists
    local test_hex_id = cQ .. "q" .. cR .. "r" .. cS .. "s"
    
    local temp_hex_obj = {
        id = test_hex_id,
        q = cQ,
        r = cR, 
        s = cS
        
    }
    if hex_grid_obj[test_hex_id] then
        return  temp_hex_obj
    else
        return false
    end
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

function get_hex_neighbour(id)
    
    local neighbours = {}
    local nNE = {} 
    local nEE = {} 
    local nSE = {} 
    local nSW = {} 
    local nWW = {} 
    local nNW = {} 
    
    if not hex_grid_obj[id] then 
        return false 
    end
    
    local coords = hex_grid_obj[id].coord
    local cQ, cR, cS = coords.q, coords.r, coords.s
    print("Id : " .. cQ .. "q" .. cR .. "r" .. cS .. "s" )
    
    nNE.q = cQ + 1
    nNE.r = cR - 1
    nNE.s = cS
    
    nNE.id = nNE.q .. "q" .. nNE.r .. "r" .. nNE.s .. "s"
    
    if hex_grid_obj[nNE.id] then
        nNE.neighbourExists = true
    else
        nNE.neighbourExists = false
    end
    
    neighbours["NE"] = nNE
    
    nEE.q = cQ + 1
    nEE.r = cR
    nEE.s = cS - 1

    nEE.id = nEE.q .. "q" .. nEE.r .. "r" .. nEE.s .. "s"
    
    if hex_grid_obj[nEE.id] then
        nEE.neighbourExists = true
    else
        nEE.neighbourExists = false
    end
    
    neighbours["EE"] = nEE
    
    nSE.q = cQ
    nSE.r = cR + 1
    nSE.s = cS - 1
    
    nSE.id = nSE.q .. "q" .. nSE.r .. "r" .. nSE.s .. "s"
    
    if hex_grid_obj[nSE.id] then
        nSE.neighbourExists = true
    else
        nSE.neighbourExists = false
    end
    
    neighbours["SE"] = nSE
    
    nSW.q = cQ -1
    nSW.r = cR + 1
    nSW.s =  cS
    
    nSW.id = nSW.q .. "q" .. nSW.r .. "r" .. nSW.s .. "s"
    
    if hex_grid_obj[nSW.id] then
        nSW.neighbourExists = true
    else
        nSW.neighbourExists = false
    end
    
    neighbours["SW"] = nSW
    
    nWW.q = cQ -1
    nWW.r = cR
    nWW.s = cS + 1
        
    nWW.id = nWW.q .. "q" .. nWW.r .. "r" .. nWW.s .. "s"
    
    if hex_grid_obj[nWW.id] then
        nWW.neighbourExists = true
    else
        nWW.neighbourExists = false
    end

    neighbours["WW"] = nWW
    
    nNW.q = cQ
    nNW.r = cR -1
    nNW.s = cS + 1

    nNW.id = nNW.q .. "q" .. nNW.r .. "r" .. nNW.s .. "s"
    
    if hex_grid_obj[nNW.id] then
        nNW.neighbourExists = true
    else
        nNW.neighbourExists = false
    end

    neighbours["NW"] = nNW

    return neighbours
    
end