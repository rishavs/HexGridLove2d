debug = true
love.math.setRandomSeed(os.time())

inspect = require "inspect"
Camera = require "camera"

local hex_size = 50
local hex_grid_gap = 0
local lvl_width_hex_count = 92
local lvl_height_hex_count = 79

local scrWidth = love.graphics.getWidth()
local scrHeight = love.graphics.getHeight()

local var_a = 0.1
local var_b = 0.6
local var_c = 0.7
local var_d = 0.4
local var_e = 0.4

local min_raw_elv = 1
local max_raw_elv = 0
local min_raw_mst = 1
local max_raw_mst = 0

    -- State Declarations ----------------------
local camX, camY, camZoom, camRot = 100, 100, 1, 0
local screenEdge = 0.95
cam = Camera(100, 100)
    
local mousex, mousey 
local hex_grid_obj = {}
local render_list = {}

function love.load(arg)

    lvl_pixel_width = round((lvl_width_hex_count + 1) * math.sqrt(3) * hex_size)
    lvl_pixel_height = round(2 * hex_size + (1.5 * hex_size * (lvl_height_hex_count -1)))
    
    generate()
end

function love.draw(dt)
    local render_count = 0
    cam:attach()
    for id, hex in pairs(hex_grid_obj) do
        local hexX, hexY = cam:cameraCoords(hex.center.x, hex.center.y)
        -- local hexX, hexY = hex.center.x, hex.center.y
        -- only render if hexes are within the screen
        if - (hex_size * 2) < hexX and hexX < scrWidth + (hex_size * 2)
            and - (hex_size * 2) < hexY and hexY < scrHeight + (hex_size * 2) then        

            love.graphics.setColor(hex.lum, hex.lum, hex.lum)
            love.graphics.polygon(hex.fillType, hex.vertices)
        
            render_count = render_count + 1
        end
    end
    cam:detach()

    -- love.graphics.print( id, hex.center.x -20, hex.center.y -20)
    
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10)    
    love.graphics.print("Hexes: ".. render_count, 10, 30)
end

local camAccl = 0
function love.update(dt)
    mousex, mousey = love.mouse.getPosition()
    
    if love.keyboard.isDown("up", "down", "left", "right") then
        camAccl = (camAccl + dt)
         
         if love.keyboard.isDown("left") then
            cam:move(-50 * camAccl, 0)
        elseif love.keyboard.isDown ('right') then
            cam:move(50 * camAccl, 0)
        elseif love.keyboard.isDown ('up') then
            cam:move(0, -50 * camAccl)
        elseif love.keyboard.isDown('down') then
            cam:move(0, 50 * camAccl)
        end
        
    else
        camAccl = 0
    end
    
end

function love.mousepressed(x, y, button)
    if button == 1 then
    
        local h_id = get_hex_id_from_point(x, y)
        if h_id then
            print("\nMouse click at: " .. x .. ", " .. y)
            print("Hex details are:")
            print(inspect(hex_grid_obj[h_id.id]))
            hex_grid_obj[h_id.id].fillType = "line"
        end
    elseif button == 2 then
        print(love.math.noise( x, y ))
    
    end
end


    -- Camera Zoom using Mouse Wheel
function love.wheelmoved(x,y)
    
    if y > 0 then
        cam.scale = cam.scale * 1.2
    elseif y < 0 then
        cam.scale = cam.scale * 0.8
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
    normalize_noise()
    -- set_basic_biomes()
    -- set_coastlines()
    -- set_shallows()
    -- set_rivers()
    -- set_habitability()
    

    -- set_habitability() 
    -- 
end

function draw_on_canvas()

end

function set_seed(s)
    local seed_min = 1000
    local seed_max = 9999
    
    if s then
        seed = s
    else
        -- Seed is a 4 digit number
        seed =  love.math.random(seed_min, seed_max ) 

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
    for h = 0, lvl_height_hex_count - 1 do
        for w = 0, lvl_width_hex_count - 1 do
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
                fillType = "fill",
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
            hex.elevation = 0
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

            local elevation = round(((elv_merged_noise + var_a) * (1 - (var_b*d_sqr^var_c))), 2)
            local water_lvl = round((var_d + var_e * d_sqr ), 2) 
            
            if elevation < water_lvl then
                hex.elevation = 0 -- here we can set elevation as ranom between 0 and water lvl when biomes is done
            else 
                hex.elevation = elevation
            end
           
            -- just debug info to find the lowest elevation
            if elevation < min_raw_elv then
                min_raw_elv = elevation
            end
            -- just debug info to find the highest elevation
            if elevation > max_raw_elv then
                max_raw_elv = elevation
            end
            
        end
        
        -- temp gradient value. will be removed when biomes are done
        hex.lum = math.min(round(hex.elevation * 255 ), 255)
        
    end
    
    print("Min Elv = " .. min_raw_elv)
    print("Max Elv = " .. max_raw_elv)
    
end

function set_moisture()

    -- will have to create the moisture seed as a function of the global seed
    love.math.setRandomSeed(seed)
    local mst_seed = love.math.random(1000, 9999)
    
    print("Moisture Seed = " .. mst_seed)
    
    local map_spr = round(lvl_height_hex_count / 10)
    
    for id, hex in pairs(hex_grid_obj) do

        if hex.elevation == 0 then
            hex.moisture = 0
        else
            local dx = 2 * hex.center.x / lvl_pixel_width - 1
            local dy = 2 * hex.center.y / lvl_pixel_height - 1

            local mst_merged_noise =
                   1.00 * love.math.noise (  1 * (dx + mst_seed),     1 * (dy + mst_seed))
                + 0.50 * love.math.noise (  2 * (dx + mst_seed),     2 * (dy + mst_seed))
                + 0.25 * love.math.noise (  4 * (dx + mst_seed),     4 * (dy + mst_seed))
                + 0.13 * love.math.noise (  8 * (dx + mst_seed),     8 * (dy + mst_seed))
                + 0.06 * love.math.noise ( 16 * (dx + mst_seed),   16 * (dy + mst_seed))
                + 0.03 * love.math.noise ( 32 * (dx + mst_seed),   32 * (dy + mst_seed))
                + 0.02 * love.math.noise ( 64 * (dx + mst_seed),   64 * (dy + mst_seed))
                + 0.01 * love.math.noise (128 * (dx + mst_seed), 128 * (dy + mst_seed))

            local moisture = round(mst_merged_noise / (2) ^ var_d, 2)

            hex.moisture = moisture
            -- hex.lum = math.min(round(moisture * 255 ), 255)
            
            -- just debug info to find the lowest elevation
            if moisture < min_raw_mst then
                min_raw_mst = moisture
            end
            -- just debug info to find the highest elevation
            if moisture > max_raw_mst then
                max_raw_mst = moisture
            end
            
        end
    end
    
    print("Min Mst = " .. min_raw_mst)
    print("Max Mst = " .. max_raw_mst)
    
end

function normalize_noise()
    for id, hex in pairs(hex_grid_obj) do
    
        local norm_elevation = math.max(round((hex.elevation - min_raw_elv) / ( max_raw_elv - min_raw_elv ), 1), 0)
        -- print(hex.elevation, norm_elevation)
        hex.elevation = norm_elevation

        local norm_moisture = math.max(round((hex.moisture - min_raw_mst) / ( max_raw_mst - min_raw_mst ), 1), 0 )
        hex.moisture = norm_moisture
    end
end

function set_basic_biomes ()
    for id, hex in pairs(hex_grid_obj) do
        -- 0 to 0.1
        if hex.elevation < 0.1 then
            hex.biome = "ocean"
            hex.tempColor = {20, 120, 200}
        -- 0.1 to 0.2
        elseif hex.elevation < 0.2 then
            hex.biome = "shallows"
            hex.tempColor = {0, 150, 250}
            
        elseif hex.elevation < 0.5 then
            hex.biome = "lowlands"
            
            if hex.moisture < 0.6 then
                hex.biome = "lowlands_beach"
                hex.tempColor = {252, 243, 207}
            elseif hex.moisture < 0.8 then
                hex.biome = "lowlands_rocky"
                hex.tempColor = {237, 187, 153}
            else
                hex.biome = "lowlands_marsh"
                hex.tempColor = {162, 217, 206}
            end

            
        elseif hex.elevation < 0.7 then
            hex.biome = "plains"
            if hex.moisture < 0.4 then
                hex.biome = "plains_arid"
                hex.tempColor = {255, 171, 145}
            elseif hex.moisture < 0.7 then
                hex.biome = "plains_grass"
                hex.tempColor = {139, 195, 74}
            else
                hex.biome = "plains_forest"
                hex.tempColor = {27, 94, 32}
            end
            
        elseif hex.elevation < 0.8 then
            hex.biome = "hills"
            if hex.moisture < 0.6 then
                hex.biome = "hills_stony"
                hex.tempColor = {188, 170, 164}
            elseif hex.moisture < 0.8 then
                hex.biome = "hills_shrubs"
                hex.tempColor = {220, 237, 200}
            else
                hex.biome = "hills_woods"
                hex.tempColor = {158, 157, 36}
            end
            
        elseif hex.elevation < 0.9 then
            hex.biome = "mountains"
            if hex.moisture < 0.6 then
                hex.biome = "mountains_rocky"
                hex.tempColor = {109, 76, 65}
            elseif hex.moisture < 0.8 then
                hex.biome = "mountains_tundra"
                hex.tempColor = {230, 238, 156}
            else
                hex.biome = "mountains_alpine"
                hex.tempColor = {129, 199, 132}
            end
        else
            hex.biome = "peaks"
            hex.tempColor = {255, 255, 255}
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