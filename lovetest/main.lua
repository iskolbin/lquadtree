local QuadTree = require('quadtree')

local SW, SH = 1280, 1024

local setColor, drawRect = love.graphics.setColor, love.graphics.rectangle

local tree = QuadTree.make( SW, SH, 4 )
local objects, nobjs = {}, 0
local collisions = {}

function love.update( dt )
	local newObjects = {}
	nobjs = 0
	for id, objvxvy in pairs( objects ) do
		local obj, vxvy = objvxvy[1], objvxvy[2]
		local vx, vy = vxvy[1], vxvy[2]
		local dx, dy = vx * dt, vy * dt
		local nx0, ny0, nx1, ny1 = obj[1]+dx, obj[2]+dy, obj[3]+dx, obj[4]+dy
		if (nx0 <= 0 and vx <= 0) or (nx1 >= SW and vx >= 0) then vx = -vx end
		if (ny0 <= 0 and vy <= 0) or (ny1 >= SH and vy >= 0) then vy = -vy end
		local tree_, newObj = QuadTree.update( tree, obj, nx0, ny0 )
		tree = tree_
		newObjects[newObj[5]] = {newObj,{vx,vy}}
		nobjs = nobjs + 1
	end
	objects = newObjects
	collisions = {}
	for id, objvxvy in pairs( objects ) do
		local obj = objects[id][1]
		local ids = QuadTree.get( tree, obj[1], obj[2], obj[3]-obj[1], obj[4]-obj[2] )
		for id_, _ in pairs( ids ) do
			if id ~= id_ then
				local obj_ = objects[id_]
				if not objects[id_] then
					print( 'error', id_ )
				else
					obj_ = obj_[1]
					if obj[1] <= obj_[3] and obj[2] <= obj_[4] and obj[3] >= obj_[1] and obj[4] >= obj_[2] then
						collisions[id] = (collisions[id] or 0) + 1
					end
				end
			end
		end
	end
end

local function drawCell( level, node, x, y, w, h )
	if level <= 0 then
		local count = 0
		for _, _ in pairs( node ) do
			count = count + 1
		end
		setColor( 255, 255, 255 )
		love.graphics.print( tostring( count ), x + 2, y + 2 )
		drawRect( 'line', x, y, w, h )
		setColor( 255, 255, 255, math.min( 255, 20*count ))
		drawRect( 'fill', x, y, w, h )
	else
		local hw, hh = w/2, h/2
		drawCell( level - 1, node[1], x, y, hw, hh )
		drawCell( level - 1, node[2], x+hw, y, hw, hh )
		drawCell( level - 1, node[3], x, y+hh, hw, hh )
		drawCell( level - 1, node[4], x+hw, y+hh, hw, hh )
	end
end

function love.draw()
	drawCell( tree.levels, tree.root, 0, 0, tree.width, tree.height )
	for id, objvxvy in pairs( objects ) do
		local obj = objvxvy[1]
		setColor( 255, math.min( 255, 32 * (collisions[id] or 0) ), 0, 128 )
		drawRect( 'fill', obj[1], obj[2], obj[3]-obj[1], obj[4]-obj[2] )
	end
	setColor( 255, 255, 255, 192 )
	drawRect( 'fill', 0, 0, 150, 60 )
	setColor( 0, 0, 0, 255 )
	love.graphics.print( 'mem(kb): ' .. math.floor(collectgarbage('count')), 5, 5 )
	love.graphics.print( 'objects: ' .. nobjs, 5, 25 )
	love.graphics.print( 'fps: ' .. love.timer.getFPS(), 5, 45 )

end

function love.mousepressed( x, y, button )
	if button == 1 then
		for i = 1, 5 do
			local tree_, newObj = QuadTree.insert( tree, x, y, 32, 32 )
			tree = tree_
			local v = math.random()*32+32
			local angle = math.random() * 2*math.pi
			objects[newObj[5]] = {newObj,{v*math.cos(angle),v*math.sin(angle)}}
		end
	elseif button == 2 then
		local tree_, todelete = tree, {}
		for id, _ in pairs( QuadTree.get( tree, x, y )) do
			local objvxvy = objects[id]
			local obj = objvxvy[1]
			if x >= obj[1] and y >= obj[2] and x <= obj[3] and y <= obj[4] then
				todelete[id] = obj
			end
		end
		for id, obj in pairs( todelete ) do
			objects[id] = nil
			tree = QuadTree.remove( tree, obj )
		end
	end
end
