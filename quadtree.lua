local QuadTree = {}

local function makeNodes( levels )
	if levels <= 0 then
		return {}
	else
		return { makeNodes( levels-1 ), makeNodes( levels-1 ), makeNodes( levels-1 ), makeNodes( levels-1 ) }
	end
end

local function copy( t )
	local obj = {}
	for k, v in pairs( t ) do
		obj[k] = v
	end
	return obj
end

function QuadTree.make( width, height, levels )
	levels = levels or 3
	return {
		id = 'QuadTree',
		cellsize = cellsize,
		root = makeNodes( levels ),
		id = 0,
		width = width,
		height = height,
		levels = levels
	}
end

local function queryGet( node, level, x, y, width, height, xywh, result )
	if level <= 0 then
		for i = 1, #node do
			result[node[i]] = node[i]
		end
		return result
	else
		local hw, hh = width / 2, height / 2
		if xywh[1] <= x + hw and xywh[2] <= y + hh and xywh[3] >= x and xywh[4] >= y then
			queryGet( node[1], level-1, x, y, hw, hh, xywh, result )
		end
		if xywh[1] <= x + width and xywh[2] <= y + hh and xywh[3] >= x + hw and xywh[4] >= y then
			queryGet( node[2], level-1, x+hw, y, hw, hh, xywh, result )
		end
		if xywh[1] <= x + hw and xywh[2] <= y + height and xywh[3] >= x and xywh[4] >= y + hh then
			queryGet( node[3], level-1, x, y+hh, hw, hh, xywh, result )
		end
		if xywh[1] <= x + width and xywh[2] <= y + height and xywh[3] >= x + hw and xywh[4] >= y + hh then
			queryGet( node[4], level-1, x+hw, y+hh, hw, hh, xywh, result )
		end
		return result
	end
end

local function queryModify( node, level, x, y, width, height, xywhid, f )
	if level <= 0 then
		return f( node, xywhid )
	else
		local hw, hh = width / 2, height / 2
		local node_ = {node[1],node[2],node[3],node[4]}
		if xywhid[1] <= x + hw and xywhid[2] <= y + hh and xywhid[3] >= x and xywhid[4] >= y then
			node_[1] = queryModify( node[1], level-1, x, y, hw, hh, xywhid, f )
		end
		if xywhid[1] <= x + width and xywhid[2] <= y + hh and xywhid[3] >= x + hw and xywhid[4] >= y then
			node_[2] = queryModify( node[2], level-1, x+hw, y, hw, hh, xywhid, f )
		end
		if xywhid[1] <= x + hw and xywhid[2] <= y + height and xywhid[3] >= x and xywhid[4] >= y + hh then
			node_[3] = queryModify( node[3], level-1, x, y+hh, hw, hh, xywhid, f )
		end
		if xywhid[1] <= x + width and xywhid[2] <= y + height and xywhid[3] >= x + hw and xywhid[4] >= y + hh then
			node_[4] = queryModify( node[4], level-1, x+hw, y+hh, hw, hh, xywhid, f )
		end
		return node_
	end
end

local function insert( node, xywhid )
	local node_, n = {}, #node
	for i = 1, n do
		node_[i] = node[i]
	end
	node_[n+1] = xywhid[5]
	return node_
end

local function remove( node, xywhid )
	local node_, n, id = {}, #node, xywhid[5]
	for i = 1, #node do
		if node[i] == id then
			for j = i+1, #node do
				node_[j-1] = node[j]
			end
			return node_
		else
			node_[i] = node[i]
		end
	end
	return node_
end

function QuadTree.insert( self, x, y, w, h )
	local o = copy( self )
	o.id = o.id+1
	o.root = queryModify( o.root, self.levels, 0, 0, self.width, self.height, {x, y, x+w, x+h, o.id}, insert )
	return o
end

function QuadTree.remove( self, id, x, y, w, h )
	local o = copy( self )
	o.root = queryModify( o.root, self.levels, 0, 0, self.width, self.height, {x, y, x+w, y+h, id}, remove )
	return o
end

function QuadTree.update( self, id, x, y, w, h, newx, newy, neww, newh )
	local o = copy( self )
	newx, newy, neww, newh = newx or x, newy or y, neww or w, newh or h
	o.root = queryModify( remove( o.root, self.levels, 0, 0, self.width, self.height, {x, y, x+w, y+h, id}, remove ), 0, 0, self.width, self.height, {newx, newy, newx + neww, newy + newh,id}, insert )
	return o
end

function QuadTree.move( self, id, x, y, w, h, newx, newy )
	local o = copy( self )
	newx, newy = newx or x, newy or y
	o.root = queryModify( remove( o.root, self.levels, 0, 0, self.width, self.height, {x, y, x+w, y+h, id}, remove ), 0, 0, self.width, self.height, {newx, newy, newx + w, newy+h,id}, insert )
	return o
end

function QuadTree.get( self, x, y, w, h )
	return queryGet( self.root, self.levels, 0, 0, self.width, self.height, {x, y, x+(w or 0), y+(h or 0)}, {} )
end

return QuadTree
