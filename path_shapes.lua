--conversion of 2d axes-aligned closed shapes to lines and curves.

local circle_3p_to_circle = require'path_circle_3p'.to_circle

local max, min, abs = math.max, math.min, math.abs

local kappa = 4 / 3 * (math.sqrt(2) - 1)

local function ellipse_to_bezier3(write, cx, cy, rx, ry)
	rx, ry = abs(rx), abs(ry)
	local lx = rx * kappa
	local ly = ry * kappa
	write('move',  cx, cy-ry)
	write('curve', cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
	write('curve', cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
	write('curve', cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
	write('curve', cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
	write('close')
end

local function circle_to_bezier3(write, cx, cy, r)
	ellipse_to_bezier3(write, cx, cy, r, r)
end

local function circle_3p_to_bezier3(write, x1, y1, x2, y2, x3, y3)
	local cx, cy, r = circle_3p_to_circle(x1, y1, x2, y2, x3, y3)
	if not cx then return end
	circle_to_bezier3(write, cx, cy, r)
end

local function rectangle_to_lines(write, x1, y1, w, h)
	local x2, y2 = x1 + w, y1 + h
	write('move', x1, y1)
	write('line', x2, y1)
	write('line', x2, y2)
	write('line', x1, y2)
	write('close')
end

local function round_rectangle_to_bezier3(write, x1, y1, w, h, rx)
	rx = min(abs(rx), abs(w/2), abs(h/2))
	local ry = rx
	local x2, y2 = x1 + w, y1 + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	local lx = rx * kappa
	local ly = ry * kappa
	local cx, cy = x2-rx, y1+ry
	write('move',  cx, y1)
	write('curve', cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
	write('line',  x2, y2-ry)
	cx, cy = x2-rx, y2-ry
	write('curve', cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
	write('line',  x1+rx, y2)
	cx, cy = x1+rx, y2-ry
	write('curve', cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
	write('line',  x1, y1+ry)
	cx, cy = x1+rx, y1+ry
	write('curve', cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
	write('close')
end

--a star has a center, two anchor points and a number of leafs
local function star_to_bezier3(write, cx, cy, x1, y1, x2, y2, n)
	error'NYI'
end

--a regular polygon has a center, a radius and a number of segments
local function regular_polygon_to_bezier3(write, cx, cy, n, r)
	error'NYI'
end

return {
	ellipse = ellipse_to_bezier3,
	circle = circle_to_bezier3,
	circle_3p = circle_3p_to_bezier3,
	rectangle = rectangle_to_lines,
	round_rectangle = round_rectangle_to_bezier3,
	star = star_to_bezier3,
	regular_polygon = regular_polygon_to_bezier3,
}
