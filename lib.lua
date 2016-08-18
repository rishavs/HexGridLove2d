-- Generated code -- http://www.redblobgames.com/grids/hexagons/



function Point(x, y)
    return {x = x, y = y}
end




function Hex(q, r, s)
    return {q = q, r = r, s = s}
end

function hex_add (a, b)
    return Hex(a.q + b.q, a.r + b.r, a.s + b.s)
end

function hex_subtract (a, b)
    return Hex(a.q - b.q, a.r - b.r, a.s - b.s)
end

function hex_scale (a, k)
    return Hex(a.q * k, a.r * k, a.s * k)
end

hex_directions = {Hex(1, 0, -1), Hex(1, -1, 0), Hex(0, -1, 1), Hex(-1, 0, 1), Hex(-1, 1, 0), Hex(0, 1, -1)}
function hex_direction (direction)
    return hex_directions[1+direction]
end

function hex_neighbor (hex, direction)
    return hex_add(hex, hex_direction(direction))
end

hex_diagonals = {Hex(2, -1, -1), Hex(1, -2, 1), Hex(-1, -1, 2), Hex(-2, 1, 1), Hex(-1, 2, -1), Hex(1, 1, -2)}
function hex_diagonal_neighbor (hex, direction)
    return hex_add(hex, hex_diagonals[1+direction])
end

function hex_length (hex)
    return math.floor((math.abs(hex.q) + math.abs(hex.r) + math.abs(hex.s)) / 2)
end

function hex_distance (a, b)
    return hex_length(hex_subtract(a, b))
end

function hex_round (h)
    local q = math.floor(math.floor (0.5 + h.q))
    local r = math.floor(math.floor (0.5 + h.r))
    local s = math.floor(math.floor (0.5 + h.s))
    local q_diff = math.abs(q - h.q)
    local r_diff = math.abs(r - h.r)
    local s_diff = math.abs(s - h.s)
    if q_diff > r_diff and q_diff > s_diff then
        q = -r - s
    else
        if r_diff > s_diff then
            r = -q - s
        else
            s = -q - r
        end
    end
    return Hex(q, r, s)
end

function hex_lerp (a, b, t)
    return Hex(a.q * (1 - t) + b.q * t, a.r * (1 - t) + b.r * t, a.s * (1 - t) + b.s * t)
end

function hex_linedraw (a, b)
    local N = hex_distance(a, b)
    local a_nudge = Hex(a.q + 0.000001, a.r + 0.000001, a.s - 0.000002)
    local b_nudge = Hex(b.q + 0.000001, b.r + 0.000001, b.s - 0.000002)
    local results = {}
    local step = 1.0 / math.max(N, 1)
    for i = 0, N do
        table.insert(results, hex_round(hex_lerp(a_nudge, b_nudge, step * i)))
    end
    return results
end




function OffsetCoord(col, row)
    return {col = col, row = row}
end

EVEN = 1
ODD = -1
function qoffset_from_cube (offset, h)
    local col = h.q
    local row = h.r + math.floor((h.q + offset * (bit32.band(h.q, 1))) / 2)
    return OffsetCoord(col, row)
end

function qoffset_to_cube (offset, h)
    local q = h.col
    local r = h.row - math.floor((h.col + offset * (bit32.band(h.col, 1))) / 2)
    local s = -q - r
    return Hex(q, r, s)
end

function roffset_from_cube (offset, h)
    local col = h.q + math.floor((h.r + offset * (bit32.band(h.r, 1))) / 2)
    local row = h.r
    return OffsetCoord(col, row)
end

function roffset_to_cube (offset, h)
    local q = h.col - math.floor((h.row + offset * (bit32.band(h.row, 1))) / 2)
    local r = h.row
    local s = -q - r
    return Hex(q, r, s)
end




function Orientation(f0, f1, f2, f3, b0, b1, b2, b3, start_angle)
    return {f0 = f0, f1 = f1, f2 = f2, f3 = f3, b0 = b0, b1 = b1, b2 = b2, b3 = b3, start_angle = start_angle}
end




function Layout(orientation, size, origin)
    return {orientation = orientation, size = size, origin = origin}
end

layout_pointy = Orientation(math.sqrt(3.0), math.sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0, math.sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5)
layout_flat = Orientation(3.0 / 2.0, 0.0, math.sqrt(3.0) / 2.0, math.sqrt(3.0), 2.0 / 3.0, 0.0, -1.0 / 3.0, math.sqrt(3.0) / 3.0, 0.0)
function hex_to_pixel (layout, h)
    local M = layout.orientation
    local size = layout.size
    local origin = layout.origin
    local x = (M.f0 * h.q + M.f1 * h.r) * size.x
    local y = (M.f2 * h.q + M.f3 * h.r) * size.y
    return Point(x + origin.x, y + origin.y)
end

function pixel_to_hex (layout, p)
    local M = layout.orientation
    local size = layout.size
    local origin = layout.origin
    local pt = Point((p.x - origin.x) / size.x, (p.y - origin.y) / size.y)
    local q = M.b0 * pt.x + M.b1 * pt.y
    local r = M.b2 * pt.x + M.b3 * pt.y
    return Hex(q, r, -q - r)
end

function hex_corner_offset (layout, corner)
    local M = layout.orientation
    local size = layout.size
    local angle = 2.0 * math.pi * (M.start_angle - corner) / 6
    return Point(size.x * math.cos(angle), size.y * math.sin(angle))
end

function polygon_corners (layout, h)
    local corners = {}
    local center = hex_to_pixel(layout, h)
    for i = 0, 5 do
        local offset = hex_corner_offset(layout, i)
        table.insert(corners, Point(center.x + offset.x, center.y + offset.y))
    end
    return corners
end




-- Tests

function complain (name)
    print("FAIL ", name)
end

function equal_hex (name, a, b)
    if not (a.q == b.q and a.s == b.s and a.r == b.r) then
        complain(name)
    end
end

function equal_offsetcoord (name, a, b)
    if not (a.col == b.col and a.row == b.row) then
        complain(name)
    end
end

function equal_int (name, a, b)
    if not (a == b) then
        complain(name)
    end
end

function equal_hex_array (name, a, b)
    equal_int(name, #a, #b)
    for i = 0, #a - 1 do
        equal_hex(name, a[1+i], b[1+i])
    end
end

function test_hex_arithmetic ()
    equal_hex("hex_add", Hex(4, -10, 6), hex_add(Hex(1, -3, 2), Hex(3, -7, 4)))
    equal_hex("hex_subtract", Hex(-2, 4, -2), hex_subtract(Hex(1, -3, 2), Hex(3, -7, 4)))
end

function test_hex_direction ()
    equal_hex("hex_direction", Hex(0, -1, 1), hex_direction(2))
end

function test_hex_neighbor ()
    equal_hex("hex_neighbor", Hex(1, -3, 2), hex_neighbor(Hex(1, -2, 1), 2))
end

function test_hex_diagonal ()
    equal_hex("hex_diagonal", Hex(-1, -1, 2), hex_diagonal_neighbor(Hex(1, -2, 1), 3))
end

function test_hex_distance ()
    equal_int("hex_distance", 7, hex_distance(Hex(3, -7, 4), Hex(0, 0, 0)))
end

function test_hex_round ()
    local a = Hex(0, 0, 0)
    local b = Hex(1, -1, 0)
    local c = Hex(0, -1, 1)
    equal_hex("hex_round 1", Hex(5, -10, 5), hex_round(hex_lerp(Hex(0, 0, 0), Hex(10, -20, 10), 0.5)))
    equal_hex("hex_round 2", hex_round(a), hex_round(hex_lerp(a, b, 0.499)))
    equal_hex("hex_round 3", hex_round(b), hex_round(hex_lerp(a, b, 0.501)))
    equal_hex("hex_round 4", hex_round(a), hex_round(Hex(a.q * 0.4 + b.q * 0.3 + c.q * 0.3, a.r * 0.4 + b.r * 0.3 + c.r * 0.3, a.s * 0.4 + b.s * 0.3 + c.s * 0.3)))
    equal_hex("hex_round 5", hex_round(c), hex_round(Hex(a.q * 0.3 + b.q * 0.3 + c.q * 0.4, a.r * 0.3 + b.r * 0.3 + c.r * 0.4, a.s * 0.3 + b.s * 0.3 + c.s * 0.4)))
end

function test_hex_linedraw ()
    equal_hex_array("hex_linedraw", {Hex(0, 0, 0), Hex(0, -1, 1), Hex(0, -2, 2), Hex(1, -3, 2), Hex(1, -4, 3), Hex(1, -5, 4)}, hex_linedraw(Hex(0, 0, 0), Hex(1, -5, 4)))
end

function test_layout ()
    local h = Hex(3, 4, -7)
    local flat = Layout(layout_flat, Point(10, 15), Point(35, 71))
    equal_hex("layout", h, hex_round(pixel_to_hex(flat, hex_to_pixel(flat, h))))
    local pointy = Layout(layout_pointy, Point(10, 15), Point(35, 71))
    equal_hex("layout", h, hex_round(pixel_to_hex(pointy, hex_to_pixel(pointy, h))))
end

function test_conversion_roundtrip ()
    local a = Hex(3, 4, -7)
    local b = OffsetCoord(1, -3)
    equal_hex("conversion_roundtrip even-q", a, qoffset_to_cube(EVEN, qoffset_from_cube(EVEN, a)))
    equal_offsetcoord("conversion_roundtrip even-q", b, qoffset_from_cube(EVEN, qoffset_to_cube(EVEN, b)))
    equal_hex("conversion_roundtrip odd-q", a, qoffset_to_cube(ODD, qoffset_from_cube(ODD, a)))
    equal_offsetcoord("conversion_roundtrip odd-q", b, qoffset_from_cube(ODD, qoffset_to_cube(ODD, b)))
    equal_hex("conversion_roundtrip even-r", a, roffset_to_cube(EVEN, roffset_from_cube(EVEN, a)))
    equal_offsetcoord("conversion_roundtrip even-r", b, roffset_from_cube(EVEN, roffset_to_cube(EVEN, b)))
    equal_hex("conversion_roundtrip odd-r", a, roffset_to_cube(ODD, roffset_from_cube(ODD, a)))
    equal_offsetcoord("conversion_roundtrip odd-r", b, roffset_from_cube(ODD, roffset_to_cube(ODD, b)))
end

function test_offset_from_cube ()
    equal_offsetcoord("offset_from_cube even-q", OffsetCoord(1, 3), qoffset_from_cube(EVEN, Hex(1, 2, -3)))
    equal_offsetcoord("offset_from_cube odd-q", OffsetCoord(1, 2), qoffset_from_cube(ODD, Hex(1, 2, -3)))
end

function test_offset_to_cube ()
    equal_hex("offset_to_cube even-", Hex(1, 2, -3), qoffset_to_cube(EVEN, OffsetCoord(1, 3)))
    equal_hex("offset_to_cube odd-q", Hex(1, 2, -3), qoffset_to_cube(ODD, OffsetCoord(1, 2)))
end

function test_all ()
    test_hex_arithmetic()
    test_hex_direction()
    test_hex_neighbor()
    test_hex_diagonal()
    test_hex_distance()
    test_hex_round()
    test_hex_linedraw()
    test_layout()
    test_conversion_roundtrip()
    test_offset_from_cube()
    test_offset_to_cube()
end



test_all()

