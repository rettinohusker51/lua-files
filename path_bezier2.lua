--math for 2d quadratic bezier curves defined as (x1, y1, x2, y2, x3, y3)
--where (x2, y2) is the control point and (x1, y1) and (x3, y3) are the end points.

local interpolate = require'path_bezier2_ai'
local hit_function = require'path_curve_hit'.hit_function
local point_distance = require'path_point'.distance

local min, max, sqrt, log = math.min, math.max, math.sqrt, math.log

--control points of a cubic bezier corresponding to a quadratic bezier.
local function bezier3_control_points(x1, y1, x2, y2, x3, y3)
	return
		(x1 + 2 * x2) / 3,
		(y1 + 2 * y2) / 3,
		(x3 + 2 * x2) / 3,
		(y3 + 2 * y2) / 3
end

--return a fair candidate for the control point of a quad bezier given its end points (x1, y1) and (x3, y3),
--and a point (x0, y0) that lies on the curve.
local function bezier2_3point_control_point(x1, y1, x0, y0, x3, y3)
	-- find a good candidate for t based on chord lengths
	local c1 = point_distance(x0, y0, x1, y1)
	local c2 = point_distance(x0, y0, x3, y3)
	local t = c1 / (c1 + c2)
	-- a point on a quad bezier is at B(t) = (1-t)^2*P1 + 2*t*(1-t)*P2 + t^2*P3
	-- solving for P2 gives P2 = (B(t) - (1-t)^2*P1 - t^2*P3) / (2*t*(1-t)) where B(t) is P0
	local x2 = (x0 - (1 - t)^2 * x1 - t^2 * x3) / (2*t * (1 - t))
	local y2 = (y0 - (1 - t)^2 * y1 - t^2 * y3) / (2*t * (1 - t))
	return x2, y2
end

--split a quad bezier at time t (t is capped between 0..1) into two curves using De Casteljau interpolation.
local function bezier2_split(t, x1, y1, x2, y2, x3, y3)
	t = min(max(t,0),1)
	local mint = 1 - t
	local x12 = x1 * mint + x2 * t
	local y12 = y1 * mint + y2 * t
	local x23 = x2 * mint + x3 * t
	local y23 = y2 * mint + y3 * t
	local x123 = x12 * mint + x23 * t
	local y123 = y12 * mint + y23 * t
	return
		x1, y1, x12, y12, x123, y123, --first curve
		x123, y123, x23, y23, x3, y3  --second curve
end

--evaluate a quad bezier at time t (t is capped between 0..1) using linear interpolation.
local function bezier2_point(t, x1, y1, x2, y2, x3, y3)
	local x, y = select(5, bezier2_split(t, x1, y1, x2, y2, x3, y3))
	return x, y
end

--length of quad bezier curve.
--closed-form solution from http://segfaultlabs.com/docs/quadratic-bezier-curve-length.
local function bezier2_length(x1, y1, x2, y2, x3, y3)
	local ax = x1 - 2*x2 + x3
	local ay = y1 - 2*y2 + y3
	local bx = 2*x2 - 2*x1
	local by = 2*y2 - 2*y1
	local A = 4*(ax*ax + ay*ay)
	local B = 4*(ax*bx + ay*by)
	local C = bx^2 + by^2
	local Sabc = 2*sqrt(A+B+C)
	local A2 = sqrt(A)
	local A32 = 2*A*A2
	local C2 = 2*sqrt(C)
	local BA = B/A2
	return (A32*Sabc + A2*B*(Sabc - C2) + (4*C*A - B^2)*log((2*A2 + BA + Sabc) / (BA+C2))) / (4*A32)
end

local bezier2_hit = hit_function(interpolate)

if not ... then require'path_hit_demo' end

return {
	bezier3_control_points = bezier3_control_points,
	bezier2_3point_control_point = bezier2_3point_control_point,
	interpolate = interpolate,
	--hit & split API
	point = bezier2_point,
	length = bezier2_length,
	split = bezier2_split,
	hit = bezier2_hit,
}

