debug = true
love.math.setRandomSeed(os.time())

local inspect = require "inspect"

local hex_size = 3
local hex_grid_gap = 0
local lvl_width_hex_count = 153
local lvl_height_hex_count = 132

local water_level =  0.00005
local var_a = 1
local var_b = 1
local var_c = 1
local var_d = 0.4
local var_e = 0.4
local var_exp = 1

local mousex, mousey 
local hex_grid_obj = {}

function love.load(arg)

    lvl_pixel_width = round((lvl_width_hex_count + 1) * math.sqrt(3) * hex_size)
    lvl_pixel_height = round(2 * hex_size + (1.5 * hex_size * (lvl_height_hex_count -1)))
    
    generate()
end

function love.draw(dt)

    for id, hex in pairs(hex_grid_obj) do
        
        if hex.biome == "empty" then
            love.graphics.setColor(50, 50, 90)
            love.graphics.polygon("line", hex.vertices)
            
        elseif hex.biome == "land" then
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
    set_moisture()
    set_biomes()

    -- set_habitability() 
end

function set_seed(s)
    if s then
        seed = s
    else
        -- Seed is a 4 digit number
        seed =  love.math.random(1000, 9999 ) 
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
                biome = "empty",
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
        print("Hex " .. test_hex_id .. " dont exist yo!")
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

    for id, hex in pairs(hex_grid_obj) do

        if hex.isOnEdge then
            hex_grid_obj[id].elevation = 0
        else
            local dx = 2 * hex.center.x / lvl_pixel_width - 1 
            local dy = 2 * hex.center.y / lvl_pixel_height - 1

            local d_sqr =  dx*dx + dy*dy
                
            local elv_merged_noise =    
                   1.00 * love.math.noise (  1 * (dx + seed),     1 * (dy + seed))
                + 0.50 * love.math.noise (  2 * (dx + seed),     2 * (dy + seed))
                + 0.25 * love.math.noise (  4 * (dx + seed),     4 * (dy + seed))
                + 0.13 * love.math.noise (  8 * (dx + seed),     8 * (dy + seed))
                + 0.06 * love.math.noise ( 16 * (dx + seed),   16 * (dy + seed))
                + 0.03 * love.math.noise ( 32 * (dx + seed),   32 * (dy + seed))
                + 0.02 * love.math.noise ( 64 * (dx + seed),   64 * (dy + seed))
                + 0.01 * love.math.noise (128 * (dx + seed), 128 * (dy + seed))

            local elevation = (elv_merged_noise / 2) ^ var_exp

            if elevation < var_d + var_e * d_sqr then
                hex_grid_obj[id].elevation = 0 -- here we can set elevation as ranom between 0 and water lvl when biomes is done
            else 
                hex_grid_obj[id].elevation = elevation
            end
            -- if elevation < var_d + var_e * d_sqr then
                -- hex_grid_obj[id].elevation = 0 -- here we can set elevation as ranom between 0 and water lvl when biomes is done
            -- elseif elevation > var_d + var_e * d_sqr and elevation < var_d *1.2 + var_e * d_sqr then
                -- hex_grid_obj[id].elevation = 2
            -- else 
                -- hex_grid_obj[id].elevation = elevation
            -- end
            -- temp gradient value. will be removed when biomes are done
            hex_grid_obj[id].lum = math.min(round(elevation * 255 ), 255)
           
        end
    end
end

function set_moisture()

    -- will have to create the moisture seed as a function of the global seed
    local mst_seed = seed
    
    local map_spr = round(lvl_height_hex_count / 10)
    
    for id, hex in pairs(hex_grid_obj) do

        if hex.elevation == 0 then
            hex_grid_obj[id].moisture = 0
        else
            local dx = 2 * hex.center.x / lvl_pixel_width - 1 
            local dy = 2 * hex.center.y / lvl_pixel_height - 1
                
            local mst_merged_noise =    
                   1.00 * love.math.noise ( 1 * (dx + seed),  ( 1 * (dy + seed)))
                + 0.50 * love.math.noise (  2 * (dx + seed),     2 * (dy + seed))
                + 0.25 * love.math.noise (  4 * (dx + seed),     4 * (dy + seed))
                + 0.13 * love.math.noise (  8 * (dx + seed),     8 * (dy + seed))
                + 0.06 * love.math.noise ( 16 * (dx + seed),   16 * (dy + seed))
                + 0.03 * love.math.noise ( 32 * (dx + seed),   32 * (dy + seed))
                + 0.02 * love.math.noise ( 64 * (dx + seed),   64 * (dy + seed))
                + 0.01 * love.math.noise (128 * (dx + seed), 128 * (dy + seed))
                    
            local moisture = round(mst_merged_noise / (2), 1)
            -- Moisture needs no normalization as it is already between 0 to 1
            hex_grid_obj[id].moisture = moisture
            hex_grid_obj[id].lum = math.min(round(moisture * 255 ), 255)
        end
    end
    
end

function set_biomes ()
    for id, hex in pairs(hex_grid_obj) do
    
        if hex.elevation == 0 then
            hex.biome = "empty"
        else
            hex.biome = "land"
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