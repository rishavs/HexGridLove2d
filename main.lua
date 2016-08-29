debug = true
love.math.setRandomSeed(os.time())

local inspect = require "inspect"

local hex_size = 3
local hex_grid_gap = 0
local lvl_width_hex_count = 153
local lvl_height_hex_count = 132

local water_level =  0.00005
local var_a = 0.5
local var_b = 0.5
local var_c = 0.1
local var_d = 0.5
local var_e = 0.5

local mousex, mousey 
local hex_grid_obj = {}

function love.load(arg)

    lvl_pixel_width = roundup((lvl_width_hex_count + 1) * math.sqrt(3) * hex_size)
    lvl_pixel_height = roundup(2 * hex_size + (1.5 * hex_size * (lvl_height_hex_count -1)))
    
    generate()
end

function love.draw(dt)

    for id, hex in pairs(hex_grid_obj) do
        
        if hex.hexType == "empty" then
            love.graphics.setColor(50, 50, 90)
            love.graphics.polygon("line", hex.vertices)
            
        elseif hex.hexType == "land" then
            love.graphics.setColor(hex.lum, hex.lum, hex.lum)
            love.graphics.polygon("fill", hex.vertices)
            
        end
        
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

function love.mousepressed(x, y, button)
    if button == 1 then
    
        local h_id = get_hex_id_from_point(x, y)
        if h_id then
            print("\nMouse click at: " .. x .. ", " .. y)
            print("Hex details are:")
            print(inspect(hex_grid_obj[h_id.id]))
        end
    elseif button == 2 then
        print(love.math.noise( x, y ))
    
    end
end


function love.keypressed(key)
    if key == "space" then
        -- reset everything
        local hex_grid_obj = {}
        generate()
    end
end
----------------------------------------------------------------

function generate()

    create_hex_grid()
    set_seed()
    set_elevation()
    -- set_moisture()
    set_biomes()

    -- set_habitability() 
end

function set_seed(s)
    if s then
        seed = s
    else
        -- Seed is a 4 digit number
        seed =  love.math.random(1, 9 ) / 10
        print("Seed : " .. seed)
    end
    
end

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
    local cQ, cR, cS = get_roundup_hex_coord( cQ_float, cR_float, cS_float)
    
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
        print("Hex " .. test_hex_id .. " dont exist yo!")
        return false
    end
end

-- Round to the nearest hex
function get_roundup_hex_coord(cX_float, cY_float, cZ_float)

    local fn_cX = roundup(cX_float)    
    local fn_cY = roundup(cY_float)
    local fn_cZ = roundup(cZ_float)
    
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

function roundup(num, dp)
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

function get_pixel_dist_between_hexes(id1, id2)
    local p1x = hex_grid_obj[id1].center.x
    local p1y = hex_grid_obj[id1].center.y
    local p2x = hex_grid_obj[id2].center.x
    local p2y = hex_grid_obj[id2].center.y

    return get_dist_between_points(p1x, p1y, p2x, p2y)
end

function get_dist_between_points(x1,y1, x2,y2) 
    return ((x2-x1)^2+(y2-y1)^2)^0.5 
end

function set_elevation()

    -- Counter to check the actual raw values of min and max elevation
    local min_elv = 1
    local max_elv = 0

    -- Setting the min and max values of elevation. These values are found by observation. Used for normalizing
    local mine = 0.3
    local maxe  = 1.4
    
    for id, hex in pairs(hex_grid_obj) do

        if hex.isOnEdge then
            hex_grid_obj[id].elevation = 0
        else
            local dx = 2 * hex.center.x / lvl_pixel_width - 1 -- change formula to use lvl_pixel_width instead
            local dy = 2 * hex.center.y / lvl_pixel_height - 1 -- change formula to use lvl_pixel_height instead
            
            -- at this point 0 <= dx <= 1 and 0 <= dy <= 1
            local d_sqr =  dx*dx + dy*dy
            
            -- Manhattan Distance
            local m_dist = 2*math.max(math.abs(dx), math.abs(dy))
            
            local elv_merged_noise =    
                   1.00 * love.math.noise (( 1 + seed) * dx, ( 1 + seed) * dy)
                + 0.50 * love.math.noise (( 2 + seed) * dx, ( 2 + seed) * dy)
                + 0.25 * love.math.noise (( 4 + seed) * dx, ( 4 + seed) * dy)
                + 0.13 * love.math.noise (( 8 + seed) * dx, ( 8 + seed) * dy)
                + 0.06 * love.math.noise ((16 + seed) * dx, (16 + seed) * dy)
                + 0.03 * love.math.noise ((32 + seed) * dx, (32 + seed) * dy)
                + 0.02 * love.math.noise ((64 + seed) * dx, (64 + seed) * dy)

            local elevation = (elv_merged_noise + var_a) * (1 - (var_b*m_dist^var_c))

            if elevation < var_d + var_e * d_sqr then
                hex_grid_obj[id].elevation = 0 -- here we can set elevation as ranom between 0 and water lvl when biomes is done
            else 
                hex_grid_obj[id].elevation = elevation
            end
            
            -- temp gradient value. will be removed when biomes are done
            hex_grid_obj[id].lum = math.min(roundup(elevation * 255 ), 255)
            
            -- just debug info to find the lowest elevation
            if elevation < min_elv then
                min_elv = elevation
            end
            -- just debug info to find the highest elevation
            if elevation > max_elv then
                max_elv = elevation
            end
            
            -- Normalize the elevation values based on mine and maxe values

            -- print("Raw Elevation = " .. hex.elevation)
            local norm_elevation = math.min((hex.elevation - mine) / ( maxe - mine ))
            -- print("Norm Elevation = " .. norme)

            hex_grid_obj[id].elevation = norm_elevation

            -- temp gradient value. will be removed when biomes are done
            hex_grid_obj[id].lum = math.min(roundup(norm_elevation * 255 ), 255)
            
            if norm_elevation < mine then
                min_norm_elv = norm_elevation
            end
            -- just debug info to find the highest elevation
            if norm_elevation > maxe then
                max_norm_elv = norm_elevation
            end

        end
    end
    
    print("Min Raw Elevation: " .. min_elv)
    print("Max Raw Elevation: " .. max_elv)
    print()

    print("Min Norm Elevation: " .. mine)
    print("Max Norm Elevation: " .. maxe)
    print()
    
end

function set_biomes ()
    for id, hex in pairs(hex_grid_obj) do
    
        if hex.elevation < water_level then
            hex.hexType = "empty"
        else
            hex.hexType = "land"
        end

    end

end

function probability(n)
    if n == 100 then
        return true
    elseif n == 0 then
        return false
    else
        local rand = math.random(0, 100)
        
        if rand < n then
            return true
        else 
            return false
        end
    end
end