local QuadTree = {}

local pairs, floor = _G.pairs, math.floor

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
		root = makeNodes( levels ),
		idcounter = 0,
		width = width,
		height = height,
		levels = levels,
		cellsize = {width/2^levels,height/2^levels}
	}
end

local function queryGet( node, level, x, y, width, height, x0, y0, x1, y1, result )
	if level <= 0 then
		for i = 1, #node do
			result[node[i]] = node[i]
		end
		return result
	else
		local hw, hh = width / 2, height / 2
		if x0 <= x + hw and y0 <= y + hh and x1 >= x and y1 >= y then
			queryGet( node[1], level-1, x, y, hw, hh, x0, y0, x1, y1, result )
		end
		if x0 <= x + width and y0 <= y + hh and x1 >= x + hw and y1 >= y then
			queryGet( node[2], level-1, x+hw, y, hw, hh, x0, y0, x1, y1, result )
		end
		if x0 <= x + hw and y0 <= y + height and x1 >= x and y1 >= y + hh then
			queryGet( node[3], level-1, x, y+hh, hw, hh, x0, y0, x1, y1, result )
		end
		if x0 <= x + width and y0 <= y + height and x1 >= x + hw and y1 >= y + hh then
			queryGet( node[4], level-1, x+hw, y+hh, hw, hh, x0, y0, x1, y1, result )
		end
		return result
	end
end

local function queryModify( node, level, x, y, width, height, rectid, f )
	if level <= 0 then
		return f( node, rectid )
	else
		local hw, hh = width / 2, height / 2
		local node_ = {node[1],node[2],node[3],node[4]}
		if rectid[1] <= x + hw and rectid[2] <= y + hh and rectid[3] >= x and rectid[4] >= y then
			node_[1] = queryModify( node[1], level-1, x, y, hw, hh, rectid, f )
		end
		if rectid[1] <= x + width and rectid[2] <= y + hh and rectid[3] >= x + hw and rectid[4] >= y then
			node_[2] = queryModify( node[2], level-1, x+hw, y, hw, hh, rectid, f )
		end
		if rectid[1] <= x + hw and rectid[2] <= y + height and rectid[3] >= x and rectid[4] >= y + hh then
			node_[3] = queryModify( node[3], level-1, x, y+hh, hw, hh, rectid, f )
		end
		if rectid[1] <= x + width and rectid[2] <= y + height and rectid[3] >= x + hw and rectid[4] >= y + hh then
			node_[4] = queryModify( node[4], level-1, x+hw, y+hh, hw, hh, rectid, f )
		end
		return node_
	end
end

local function insert( node, rectid )
	local node_, n = {}, #node
	for i = 1, n do
		node_[i] = node[i]
	end
	node_[n+1] = rectid[5]
	return node_
end

local function remove( node, rectid )
	local node_, n, id = {}, #node, rectid[5]
	for i = 1, n do
		if node[i] == id then
			for j = i+1, n do
				node_[j-1] = node[j]
			end
			return node_
		else
			node_[i] = node[i]
		end
	end
	return node_
end

function QuadTree.insert( self, x, y, w, h, cx0, cy0, cx1, cy1 )
	local o = copy( self )
	local id = o.idcounter+1
	if id < 2^52 then
		local cellsize = self.cellsize
		local rectid = {x, y, x+w, y+h, id, cx0 or floor(x/cellsize[1]), cy0 or floor(y/cellsize[2]), cx1 or floor((x+w)/cellsize[1]), cy1 or floor((y+h)/cellsize[2])}
		o.root = queryModify( o.root, self.levels, 0, 0, self.width, self.height, rectid, insert )
		o.idcounter = id
		return o, rectid
	else
		return nil
	end
end

function QuadTree.remove( self, rectid )
	local o = copy( self )
	o.root = queryModify( o.root, self.levels, 0, 0, self.width, self.height, rectid, remove )
	return o
end

function QuadTree.update( self, rectid, nx, ny, nw, nh )
	local cellsize = self.cellsize
	local cx0, cy0 = floor( nx/cellsize[1] ), floor( ny/cellsize[2] )
	nx, ny, nw, nh = nx or rectid[1], ny or rectid[2], nw or (rectid[3]-rectid[1]), nh or (rectid[4]-rectid[2])
	local cx1, cy1 = floor( (nx+nw)/cellsize[1] ), floor( (ny+nh)/cellsize[2] )
	if cx0 ~= rectid[6] or cy0 ~= rectid[7] or cx1 ~= rectid[8] or cy1 ~= rectid[9] then
		return QuadTree.insert( QuadTree.remove( self, rectid ), nx, ny, nw, nh, cx0, cy0, cx1, cy1 )
	else
		return self, {nx, ny, nx+nw, ny+nh, rectid[5], cx0, cy0, cx1, cy1}
	end
end

function QuadTree.get( self, x, y, w, h, result )
	return queryGet( self.root, self.levels, 0, 0, self.width, self.height, x, y, x+(w or 0), y+(h or 0), result or {} )
end

return QuadTree
