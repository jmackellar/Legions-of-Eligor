--- map.lua
--- Map table, tiles, and held creatures and items.

local mapStartX = 1
local mapStartY = 2

local mapWidth = 80
local mapHeight = 20
local map = { }
local mapSeen = { }

local mapCurrentBranch = 'Dungeon'
local mapCurrentFloor = 1

local mapPlayerSObject = 'random'
local mapObjects = { }

--- debug flags
debugDisableFog = false

--- mapInit
--- Create a new blank map
function mapInit(w, h)
	mapWidth = w
	mapHeight = h
	map = { }
	mapFog = { }
	for x = 1, mapWidth do
		map[x] = { }
		mapFog[x] = { }
		for y = 1, mapHeight do
			map[x][y] = mapTiles.floor
			mapFog[x][y] = {seen = false, lit = false}
		end
	end
end

--- mapDraw
--- prints map characters to the simulated console.
function mapDraw()
	for x = 1, mapWidth do
		for y = 1, mapHeight do		
			mapDrawTile(x, y)
		end
	end
end

--- mapGenerateCreatures
--- spawns the maps creatures.
function mapGenerateCreatures()
	creatureClearAll()
	local c = mapBranch[mapCurrentBranch].creatures
	local cMin = mapBranch[mapCurrentBranch].minCreatures
	local cMax = mapBranch[mapCurrentBranch].maxCreatures
	local total = math.random(cMin, cMax)
	for i = 1, # c do
		for j = 1, math.ceil(total * (c[i].perc / 100)) do
			local placed = false
			while not placed do
				local x = math.random(2, mapWidth - 1)
				local y = math.random(2, mapHeight - 1)
				if map[x][y].walkThru and playerIsTileFree(x, y) and creatureIsTileFree(x, y) then
					creatureSpawn(x, y, c[i].name)
					placed = true
				end
			end
		end
	end
end

--- mapSaveCreatures
--- saves creatures for current map.
function mapSaveCreatures()
	local pre = tostring(mapCurrentBranch .. mapCurrentFloor)
	creatureSave(pre)
end

--- mapLoadCreatures
--- loads creatures for current map.
function mapLoadCreatures()
	local pre = tostring(mapCurrentBranch .. mapCurrentFloor)
	creatureLoad(pre)
end

--- mapSaveItems
--- saves items for current map.
function mapSaveItems()
	local pre = tostring(mapCurrentBranch .. mapCurrentFloor)
	itemSave(pre)
end

--- mapLoadItems
--- loads items for current map.
function mapLoadItems()
	local pre = tostring(mapCurrentBranch .. mapCurrentFloor)
	itemLoad(pre)
end

--- mapSave
--- saves the map.
function mapSave()
	mapSaveCreatures()
	mapSaveItems()
	m = tostring(mapCurrentBranch .. mapCurrentFloor .. ".lua")
	mf = tostring(mapCurrentBranch .. mapCurrentFloor .. "fog.lua")
	mo = tostring(mapCurrentBranch .. mapCurrentFloor .. "objects.lua")
	love.filesystem.newFile(m)
	love.filesystem.newFile(mf)
	love.filesystem.newFile(mo)
	love.filesystem.write(m, Ser(map))
	love.filesystem.write(mf, Ser(mapFog))
	love.filesystem.write(mo, Ser(mapObjects))
end

--- mapLoad
--- loads a map.  Returns true if loaded, false if no map could be loaded.
function mapLoad()
	mapLoadCreatures()
	mapLoadItems()
	m = tostring(mapCurrentBranch .. mapCurrentFloor .. ".lua")
	mf = tostring(mapCurrentBranch .. mapCurrentFloor .. "fog.lua")
	mo = tostring(mapCurrentBranch .. mapCurrentFloor .. "objects.lua")
	if love.filesystem.exists(m) and love.filesystem.exists(mf) and love.filesystem.exists(mo) then
		local c1 = love.filesystem.load(m)
		local c2 = love.filesystem.load(mf)
		local c3 = love.filesystem.load(mo)
		map = c1()
		mapFog = c2()
		mapObjects = c3()
		return true
	end
	return false
end

--- mapChangeFloor
--- moves up or down stairs.
function mapChangeFloor(dy, save)
	local s = save or 'yes'
	if dy == -1 and mapCurrentFloor == 1 then return end
	if dy == 1 and mapCurrentFloor == mapBranch[mapCurrentBranch].floors then return end
	if s == 'yes' then mapSave() end
	mapCurrentFloor = mapCurrentFloor + dy
	if not mapLoad() then
		--- a map for this level doesnt already exist, generate a new one
		if mapBranch[mapCurrentBranch].gen == 'mapGenCave' then
			mapGenCave(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenDungeon' then
			mapGenDungeon(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenJails' then
			mapGenJails(mapWidth, mapHeight)
		end
	else
		playerDisableFog()
		--- give player correct spawn point
		if playerGetPrev() == 'up' then
			mapPlayerOSpawn = 'upstairs'
		elseif playerGetPrev() == 'down' then
			mapPlayerOSpawn = 'downstairs'
		end
		--- map loaded. move player to SObject and cast fog
		playerEnableFog()
		mapMovePlayerToSObject()
	end
	playerCastFog()
	gameSetRedrawAll()
end

--- mapChangeBranch
--- changes map branch
function mapChangeBranch(branch)
	mapCurrentBranch = branch
	mapCurrentFloor = 1
	mapChangeFloor(0)
end

--- mapUseConnection
--- Player uses a connection.
function mapUseConnection(x, y)
	local oldBranch = mapCurrentBranch
	gameSave()
	for i = 1, # mapObjects do
		if mapObjects[i].x == x and mapObjects[i].y == y then
			mapCurrentBranch = mapObjects[i].connection
			mapCurrentFloor = mapObjects[i].drop
			messageRecieve("You enter the " .. mapBranch[mapCurrentBranch].intro)
		end
	end
	playerDisableFog()
	mapChangeFloor(0, 'no')
	for i = 1, # mapObjects do
		if mapObjects[i].connection == oldBranch then
			playerMoveTo(mapObjects[i].x, mapObjects[i].y)			
		end
	end
	playerEnableFog()
	playerCastFog()
end

--- mapDrawTile
--- draws specified tile.
function mapDrawTile(x, y)
	if x < 1 and x > mapWidth and y < 1 and y > mapHeight then return end
	local xx = mapStartX + (x - 1)
	local yy = mapStartY + (y - 1)
	if not debugDisableFog then
		local tC = map[x][y].textColor		
		if mapFog[x][y].lit then		
			consolePut({x = xx, y = yy, char = map[x][y].char, backColor = map[x][y].backColor, textColor = tC})
		elseif mapFog[x][y].seen then
			local tc = {tC[1], tC[2], tC[3], 100}
			consolePut({x = xx, y = yy, char = map[x][y].char, backColor = map[x][y].backColor, textColor = tc})
		else
			consolePut({x = xx, y = yy, char = ' ', backColor = {0, 0, 0, 255}, textColor = {0, 0, 0, 255}})
		end
	else
		local tC = map[x][y].textColor
		consolePut({x = xx, y = yy, char = map[x][y].char, backColor = map[x][y].backColor, textColor = tC})
	end
end

--- mapGenJails
--- roguelike dungeon with jail cells and holding areas.
function mapGenJails(w, h)
	mapInit(w, h)
	print('go')
	local rooms = { }
	local roomsMax = math.random(4, 5)
	local mw = 20
	local mh = 9
	local xx = 0
	local yy = 0
	local ww = 0
	local hh = 0
	local tries = 0
	local open = true
	
	--- First fill the map with walls.  Rooms and cooridors will be carved out later.
	for x = 1, w do
		for y = 1, h do
			map[x][y] = mapTiles.blank
		end
	end
	
	--- Begin making rooms.  
	--- Randomly generate room location and size, select random room type, and
	--- check for collisions with other rooms.
	while # rooms < roomsMax do
		ww = math.random(12, mw)
		hh = math.random(7, mh)
		xx = math.random(3, mapWidth - 3 - mw)
		yy = math.random(2, mapHeight - 2 - mh)
		if ww % 2 ~= 0 then
			ww = ww + 1
		end
		if hh % 2 ~= 0 then
			hh = hh + 1
		end
		if # rooms == 0 then
			--- first room will have the staircase to the above level if applicable.
			table.insert(rooms, {x = xx, y = yy, w = ww, h = hh, type = 'staircase'})
		else
			--- Generate room type.
			local rt = math.random(1, 2)
			if rt == 1 then 
				rt = 'cells'
			elseif rt == 2 then
				rt = 'holding'
			end
			if # rooms == roomsMax - 1 then
				rt = 'downcase'
			end
			--- Check for collision with other rooms.  If collision,
			--- then discard room and start again.
			local make = true
			for i = 1, # rooms do
				if xx < rooms[i].x + rooms[i].w and 
				   xx + ww > rooms[i].x and
				   yy < rooms[i].y + rooms[i].h and
				   yy + hh > rooms[i].y then
				   make = false
				end
			end
			if make then	--- Open! place our room now :3
				table.insert(rooms, {x = xx, y = yy, w = ww, h = hh, type = rt})
			end
		end
		tries = tries + 1
		if tries >= 30 then
			break
		end
	end
	
	--- Carve rooms into the map.
	for i = 1, # rooms do
		for x = rooms[i].x, rooms[i].x + rooms[i].w do
			for y = rooms[i].y, rooms[i].y + rooms[i].h do
				--- If the tile is on the outside carve walls.  Else
				--- the inside has floors carved out.
				if x == rooms[i].x or x == rooms[i].x + rooms[i].w or y == rooms[i].y or y == rooms[i].y + rooms[i].h then
					map[x][y] = mapTiles.smoothwall
				else
					map[x][y] = mapTiles.floor
				end
			end
		end
	end
	
	--- Carve corridors between rooms.
	for i = 1, # rooms - 1 do
		--- Horizontal corridor.
		local var = math.random(0, 1) if var == 0 then var = -1 end
		for x = math.min(rooms[i].x + math.floor(rooms[i].w / 2), rooms[i+1].x + math.floor(rooms[i+1].w / 2)), math.max(rooms[i].x + math.floor(rooms[i].w / 2), rooms[i+1].x + math.floor(rooms[i+1].w / 2)) do
			--- If the map tile we are trying to carve from is blank then
			--- carve out a corridor tile. Else if the tile is a wall then
			--- then create a closed door.  Else if the tile is a floor
			--- then leave it.
			if map[x][rooms[i].y + math.floor(rooms[i].h / 2) + var] == mapTiles.blank then
				map[x][rooms[i].y + math.floor(rooms[i].h / 2) + var] = mapTiles.cooridorfloor
			elseif map[x][rooms[i].y + math.floor(rooms[i].h / 2) + var] == mapTiles.smoothwall then
				map[x][rooms[i].y + math.floor(rooms[i].h / 2) + var] = mapTiles.cooridorfloor
			else
				--- Do nothing!
			end
		end
		--- Vertical corridor.
		for y = math.min(rooms[i].y + math.floor(rooms[i].h / 2), rooms[i+1].y + math.floor(rooms[i+1].h / 2)), math.max(rooms[i].y + math.floor(rooms[i].h / 2), rooms[i+1].y + math.floor(rooms[i+1].h / 2)) do
			--- If the map tile we are trying to carve from is blank then
			--- carve out a corridor tile. Else if the tile is a wall then
			--- then create a closed door.  Else if the tile is a floor
			--- then leave it.
			if map[rooms[i+1].x + math.floor(rooms[i+1].w / 2) + var][y] == mapTiles.blank then
				map[rooms[i+1].x + math.floor(rooms[i+1].w / 2) + var][y] = mapTiles.cooridorfloor
			elseif map[rooms[i+1].x + math.floor(rooms[i+1].w / 2) + var][y] == mapTiles.smoothwall then
				map[rooms[i+1].x + math.floor(rooms[i+1].w / 2) + var][y] = mapTiles.cooridorfloor
			else
				--- Do nothing!
			end
		end
	end
	
	--- Room type decorations
	for i = 1, # rooms do
		if rooms[i].type == 'cells' then
			--- middle x and y coordinates
			local x = math.ceil(rooms[i].x + rooms[i].w / 2)
			local y = math.ceil(rooms[i].y + rooms[i].h / 2)
			--- the wall we don't put a door on
			local w = math.random(1, 5)
			for xx = rooms[i].x + 1, rooms[i].x + rooms[i].w - 1 do
				map[xx][y] = mapTiles.smoothwall
				if xx == rooms[i].x + 1 + 2 and w ~= 1 then
					map[xx][y] = mapTiles.closeddoor
				elseif xx == rooms[i].x + rooms[i].w - 1 - 2 and w ~= 2 then
					map[xx][y] = mapTiles.closeddoor 
				end
			end
			for yy = rooms[i].y + 1, rooms[i].y + rooms[i].h - 1 do
				map[x][yy] = mapTiles.smoothwall
				if yy == rooms[i].y + 1 + 1 and w ~= 3 then
					map[x][yy] = mapTiles.closeddoor
				elseif yy == rooms[i].y + rooms[i].h - 1 - 1 and w ~= 4 then
					map[x][yy] = mapTiles.closeddoor
				end
			end
		elseif rooms[i].type == 'holding' then
			--- middle x and y coordinates
			local x = math.ceil(rooms[i].x + rooms[i].w / 2)
			local y = math.ceil(rooms[i].y + rooms[i].h / 2)
			if math.random(1, 2) == 1 then
				local w = math.random(1, 2)
				--- wall going horizontally across the room.
				for xx = rooms[i].x + 1, rooms[i].x + rooms[i].w - 1 do
					map[xx][y] = mapTiles.smoothwall
					if xx == rooms[i].x + 1 + 2 and w ~= 1 then
						map[xx][y] = mapTiles.closeddoor
					elseif xx == rooms[i].x + rooms[i].w - 1 - 2 and w ~= 2 then
						map[xx][y] = mapTiles.closeddoor 
					end
				end
			else
				local w = math.random(3, 4)
				--- wall going vertically across the room.
				for yy = rooms[i].y + 1, rooms[i].y + rooms[i].h - 1 do
					map[x][yy] = mapTiles.smoothwall
					if yy == rooms[i].y + 1 + 1 and w ~= 3 then
						map[x][yy] = mapTiles.closeddoor
					elseif yy == rooms[i].y + rooms[i].h - 1 - 1 and w ~= 4 then
						map[x][yy] = mapTiles.closeddoor
					end
				end
			end
		elseif rooms[i].type == 'staircase' then
			if mapCurrentFloor > 1 then
				map[rooms[i].x + 3][rooms[i].y + 2] = mapTiles.upstairs
				mapPlaceUpstairs(rooms[i].x + 3, rooms[i].y + 2)
			end
		elseif rooms[i].type == 'downcase' then
			if mapCurrentFloor < mapBranch[mapCurrentBranch].floors then
				map[rooms[i].x + rooms[i].w - 3][rooms[i].y + rooms[i].h - 2] = mapTiles.downstairs
				mapPlaceDownstairs(rooms[i].x + rooms[i].w - 3, rooms[i].y + rooms[i].h - 2)
			end
		end
	end
	
	mapMovePlayerToSObject()
	playerCastFog()
	mapGenerateCreatures()
	itemGenerate()
	mapPlaceSpecialTiles()
	mapPlaceConnections()
	gameSetRedrawAll()
	
	if # rooms < roomsMax then
		mapGenJails(mapWidth, mapHeight)
	end
	
end

--- mapGenDungeon
--- Generic roguelike dungeon generation.
function mapGenDungeon(w, h)
	mapInit(w, h)
	
	local rooms = { }
	local roomsMax = math.random(5, 7)
	local mw = 15
	local mh = 8
	local xx = 0
	local yy = 0
	local ww = 0
	local hh = 0
	local open = true
	--- fill map with walls
	for x = 1, w do
		for y = 1, h do
			map[x][y] = mapTiles.blank
		end
	end
	--- make first room
	ww = math.random(6, mw)
	hh = math.random(5, mh)
	xx = math.random(3, 25 - 3 - ww)
	yy = math.random(2, mapHeight - 2 - hh)
	table.insert(rooms, {x = xx, y = yy, w = ww, h = hh})
	--- make second room
	ww = math.random(6, mw)
	hh = math.random(5, mh)
	xx = math.random(27, 50 - 3 - ww)
	yy = math.random(2, mapHeight - 2 - hh)
	table.insert(rooms, {x = xx, y = yy, w = ww, h = hh})
	--- make third room
	ww = math.random(6, mw)
	hh = math.random(5, mh)
	xx = math.random(53, mapWidth - 3 - ww)
	yy = math.random(2, mapHeight - 2 - hh)
	table.insert(rooms, {x = xx, y = yy, w = ww, h = hh})
	--- make more rooms now
	while # rooms < roomsMax do
		ww = math.random(5, mw)
		hh = math.random(4, mh)
		xx = math.random(3, mapWidth - 3 - ww)
		yy = math.random(2, mapHeight - 2 - hh)
		open = true
		for i = 1, # rooms do
			if xx < rooms[i].x + rooms[i].w and 
			   xx + ww > rooms[i].x and
			   yy < rooms[i].y + rooms[i].h and
			   yy + hh > rooms[i].y then
				open = false
			end
		end
		if open then
			table.insert(rooms, {x = xx, y = yy, w = ww, h = hh})
		end
	end
	--- place rooms onto map
	for i = 1, # rooms do
		for x = rooms[i].x, rooms[i].x + rooms[i].w do
			map[x][rooms[i].y] = mapTiles.smoothwall
			map[x][rooms[i].y + rooms[i].h] = mapTiles.smoothwall
		end
		for y = rooms[i].y, rooms[i].y + rooms[i].h do
			map[rooms[i].x][y] = mapTiles.smoothwall
			map[rooms[i].x + rooms[i].w][y] = mapTiles.smoothwall
		end
		for x = rooms[i].x + 1, rooms[i].x + rooms[i].w - 1 do
			for y = rooms[i].y + 1, rooms[i].y + rooms[i].h - 1 do
				if x >= 1 and x <= mapWidth and y >= 1 and y <= mapHeight then
					map[x][y] = mapTiles.floor
				end
			end
		end
	end
	--- place tunnels between rooms
	for i = 1, # rooms - 1 do
		local cx1 = rooms[i].x + math.floor(rooms[i].w / 2)
		local cy1 = rooms[i].y + math.floor(rooms[i].h / 2)
		if i == # rooms then
			i = 0
		end
		local cx2 = rooms[i+1].x + math.floor(rooms[i+1].w / 2)
		local cy2 = rooms[i+1].y + math.floor(rooms[i+1].h / 2)
		for x = math.min(cx1, cx2), math.max(cx2, cx1) do
			if map[x][cy1] == mapTiles.blank or map[x][cy1] == mapTiles.smoothwall then
				map[x][cy1] = mapTiles.floor			
			end
		end
		for y = math.min(cy1, cy2), math.max(cy2, cy1) do
			if map[cx2][y] == mapTiles.smoothwall or map[cx2][y] == mapTiles.smoothwall then
				map[cx2][y] = mapTiles.floor				
			end
		end
	end
	--- make cooridors in some tunnels between rooms
	for i = 1, # rooms - 1 do
		local cx1 = rooms[i].x + math.floor(rooms[i].w / 2)
		local cy1 = rooms[i].y + math.floor(rooms[i].h / 2)
		if i == # rooms then
			i = 0
		end
		local cx2 = rooms[i+1].x + math.floor(rooms[i+1].w / 2)
		local cy2 = rooms[i+1].y + math.floor(rooms[i+1].h / 2)
		for x = math.min(cx1, cx2), math.max(cx2, cx1) do
			if (map[x][cy1-1] == mapTiles.blank or map[x][cy1-1] == mapTiles.smoothwall) and (map[x][cy1+1] == mapTiles.blank or map[x][cy1+1] == mapTiles.smoothwall) then
				map[x][cy1] = mapTiles.cooridorfloor
			elseif (map[x][cy1-1] == mapTiles.blank or map[x][cy1-1] == mapTiles.smoothwall) and (map[x-1][cy1-1] == mapTiles.blank or map[x-1][cy1-1] == mapTiles.smoothwall) and (map[x+1][cy1+1] == mapTiles.blank or map[x+1][cy1+1] == mapTiles.smoothwall) then
				map[x][cy1] = mapTiles.cooridorfloor
			end
			if (map[x][cy1] == mapTiles.blank or map[x][cy1] == mapTiles.smoothwall) and map[x-1][cy1] == mapTiles.floor and map[x][cy1+1] == mapTiles.floor then
				map[x][cy1] = mapTiles.floor
			elseif map[x][cy1] == mapTiles.cooridorfloor and map[x-1][cy1] == mapTiles.floor and map[x][cy1+1] == mapTiles.floor then
				map[x][cy1] = mapTiles.floor
			end
		end
		for y = math.min(cy1, cy2), math.max(cy2, cy1) do
			if (map[cx2-1][y] == mapTiles.blank or map[cx2-1][y] == mapTiles.smoothwall) and (map[cx2+1][y] == mapTiles.blank or map[cx2+1][y] == mapTiles.smoothwall) then
				map[cx2][y] = mapTiles.cooridorfloor
			end
			if (map[cx2][y] == mapTiles.blank or map[cx2][y] == mapTiles.smoothwall) and map[cx2-1][y] == mapTiles.floor and map[cx2][y+1] == mapTiles.floor then
				map[cx2][y] = mapTiles.floor
			end
		end
	end
	--- place doors
	for i = 1, # rooms do
		--- top and bot walls
		for x = rooms[i].x, rooms[i].w + rooms[i].x do
			local y1 = rooms[i].y
			local y2 = rooms[i].y + rooms[i].h
			--- top wall
			if map[x][y1].name == "floor" and map[x-1][y1] == mapTiles.smoothwall and map[x+1][y1] == mapTiles.smoothwall then
				map[x][y1] = mapTiles.closeddoor
			end
			--- bot wall
			if map[x][y2].name == "floor" and map[x-1][y2] == mapTiles.smoothwall and map[x+1][y2] == mapTiles.smoothwall then
				map[x][y2] = mapTiles.closeddoor
			end
		end
		--- left and right walls
		for y = rooms[i].y, rooms[i].y + rooms[i].h do
			local x1 = rooms[i].x
			local x2 = rooms[i].x + rooms[i].w
			--- left wall
			if map[x1][y].name == "floor" and map[x1][y-1] == mapTiles.smoothwall and map[x1][y+1] == mapTiles.smoothwall then
				map[x1][y] = mapTiles.closeddoor
			end
			--- right wall
			if map[x2][y].name == "floor" and map[x2][y-1] == mapTiles.smoothwall and map[x2][y+1] == mapTiles.smoothwall then
				map[x2][y] = mapTiles.closeddoor
			end
		end
	end
	
	--- turn all blank tiles that border a floor tile into a wall
	for x = 2, mapWidth - 1 do
		for y = 2, mapHeight - 1 do
			if map[x][y] == mapTiles.blank then
				if map[x-1][y] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
				if map[x+1][y] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
				if map[x][y-1] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
				if map[x][y+1] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
				if map[x-1][y-1] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
				if map[x+1][y-1] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
				if map[x-1][y+1] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
				if map[x+1][y+1] == mapTiles.floor then map[x][y] = mapTiles.smoothwall end
			end
		end
	end
	
	--- place upstairs in room 1 if applicable
	if mapCurrentFloor > 1 then
		local r = rooms[1]
		local x = math.random(r.x + 1, r.x + r.w - 1)
		local y = math.random(r.y + 1, r.y + r.h - 1)
		mapPlaceUpstairs(x, y)
	end
	--- place downstairs in last room if applicable
	if mapCurrentFloor < mapBranch[mapCurrentBranch].floors then
		local r = rooms[#rooms]
		local x = math.random(r.x + 1, r.x + r.w - 1)
		local y = math.random(r.y + 1, r.y + r.h - 1)
		mapPlaceDownstairs(x, y) 
	end
	
	--- spawn
	if mapCurrentFloor == 1 and playerGetPrev() == 'spawn' then
		local r = rooms[math.random(1, #rooms)]
		local x = math.random(r.x + 1, r.x + r.w - 1)
		local y = math.random(r.y + 1, r.y + r.h - 1)
		mapPlayerSX = x
		mapPlayerSY = y
	end
	
	mapMovePlayerToSObject()
	playerCastFog()
	mapGenerateCreatures()
	itemGenerate()
	mapPlaceSpecialTiles()
	mapPlaceConnections()
	gameSetRedrawAll()
end

--- mapGenCave
--- Cellular automata cave generation
function mapGenCave(w, h)
	mapInit(w, h)
	--- First place down random walls.  no more than 45% of the
	--- map tiles are allowed to become walls.
	local maxWalls = (mapWidth * mapHeight) * 0.40
	local placedWalls = 0
	while placedWalls < maxWalls do
		for x = 1, mapWidth do
			for y = 1, mapHeight do
				local chance = 40
				--chance = chance + math.abs(x - 40) / 4
				--chance = chance + math.abs(y - 10)
				if math.random(1, 100) <= chance and placedWalls < maxWalls then
					map[x][y] = mapTiles.wall
					placedWalls = placedWalls + 1
				end
			end
		end
	end
	--- Place boundary wall at room edge
	for x = 1, mapWidth do
		map[x][1] = mapTiles.wall
		map[x][2] = mapTiles.wall
		map[x][mapHeight] = mapTiles.wall
		map[x][mapHeight-1] = mapTiles.wall
	end
	for y = 1, mapHeight do
		map[1][y] = mapTiles.wall
		map[2][y] = mapTiles.wall
		map[mapWidth][y] = mapTiles.wall
		map[mapWidth-1][y] = mapTiles.wall
	end
	--- Cellular automata.  Sweep over every tile.  If the tile has 4 or more neighbouring walls,
	--- including itself, then the tile becomes a wall.  Else the tile becomes a floor.  Repeat
	--- a few times.
	for i = 1, 6 do
		for x = 3, mapWidth - 2 do
			for y = 3, mapHeight - 2 do
				--- Count up neighbouring walls
				local w = 0
				for xx = x - 1, x + 1 do
					for yy = y - 1, y + 1 do
						if map[xx][yy] == mapTiles.wall then
							w = w + 1
						end
					end
				end
				local w2 = 0
				for xx = x - 2, x + 2 do
					for yy = y - 2, y + 2 do
						if map[xx][yy] == mapTiles.wall then
							w2 = w2 + 1
						end
					end
				end
				if i <= 4 then
					if w >= 5 or w2 <= 3 then
						map[x][y] = mapTiles.wall
					else
						map[x][y] = mapTiles.floor
					end
				else
					if w >= 5 then
						map[x][y] = mapTiles.wall
					else
						map[x][y] = mapTiles.floor
					end
				end
			end
		end
	end
	--- decide if we should throw away the map or not
	local x = math.random(3, mapWidth - 2)
	local y = math.random(3, mapHeight - 2)
	--- FLOOOOD FIIIILLLL
	local open = { }
	local closed = { }
	table.insert(open, {x, y})
	while # open > 0 do
		local c = open[1]
		if map[c[1] - 1][c[2]] == mapTiles.floor then
			if not mapGenCaveHelperIsCoordInTable(c[1] - 1, c[2], open) and not mapGenCaveHelperIsCoordInTable(c[1] - 1, c[2], closed) then 
				table.insert(open, {c[1] - 1, c[2]}) 
			end
		end
		if map[c[1] + 1][c[2]] == mapTiles.floor then
			if not mapGenCaveHelperIsCoordInTable(c[1] + 1, c[2], open) and not mapGenCaveHelperIsCoordInTable(c[1] + 1, c[2], closed) then 
				table.insert(open, {c[1] + 1, c[2]}) 
			end
		end
		if map[c[1]][c[2 - 1]] == mapTiles.floor then
			if not mapGenCaveHelperIsCoordInTable(c[1], c[2 - 1], open) and not mapGenCaveHelperIsCoordInTable(c[1], c[2 - 1], closed) then 
				table.insert(open, {c[1], c[2 - 1]}) 
			end
		end
		if map[c[1]][c[2 + 1]] == mapTiles.floor then
			if not mapGenCaveHelperIsCoordInTable(c[1], c[2 + 1], open) and not mapGenCaveHelperIsCoordInTable(c[1], c[2 + 1], closed) then 
				table.insert(open, {c[1], c[2 + 1]}) 
			end
		end
		table.insert(closed, {c[1], c[2]})
		table.remove(open, 1)
	end	
	
	--- if # of floor tiles in the flood fill is too low, make a new map
	if # closed > 450 and # closed < 650 then
		---  stairs
		--- new game spawn
		mapObjects = { }
		if mapCurrentFloor == 1 and playerGetPrev() == 'spawn' then
			local i = math.random(1, # closed)
			local tile = closed[i]	
			mapPlayerSX = tile[1]
			mapPlayerSY = tile[2]
		end
		
		--- first do we need up stairs?
		if mapCurrentFloor > 1 then
			--- place upstairs
			local i = math.random(1, # closed)
			local tile = closed[i]	
			mapPlaceUpstairs(tile[1], tile[2])
			table.remove(closed, i)
		end
		
		--- do we need down stairs?
		if mapCurrentFloor < mapBranch[mapCurrentBranch].floors then
			--- place downstairs
			local i = math.random(1, # closed)
			local tile = closed[i]
			mapPlaceDownstairs(tile[1], tile[2])
		end
		
		--- move player
		mapMovePlayerToSObject()
		playerCastFog()
		mapPlaceSpecialTiles()
		mapPlaceConnections()
		itemGenerate()
		mapGenerateCreatures()
		gameSetRedrawAll()
		
	else
		--- BAD MAP, REMAKE
		mapGenCave(mapWidth, mapHeight)
	end
	
end

--- mapPlaceConnections
--- places map branch connections.
function mapPlaceConnections()
	local connections = mapBranch[mapCurrentBranch].connections
	for i = 1, # connections do
		if connections[i].floor == mapCurrentFloor then
			local placed = false
			repeat
				local x = math.random(1, mapWidth)
				local y = math.random(1, mapHeight)
				if map[x][y] == mapTiles.floor or map[x][y].name == 'floor' then
					placed = true
					map[x][y] = mapTiles.connection
					table.insert(mapObjects, {name = 'connection', connection = connections[i].branch, drop = connections[i].drop, x = x, y = y})
				end
			until placed
		end
	end
end

--- mapPlaceUpstairs
--- places the upstairs.
function mapPlaceUpstairs(x, y)
	map[x][y] = mapTiles.upstairs
	table.insert(mapObjects, {name = 'upstairs', x = x, y = y})
	if playerGetPrev() == 'up' then
		mapPlayerOSpawn = 'upstairs'
	end
end

--- mapPlaceDownstairs
--- places the downstairs.
function mapPlaceDownstairs(x, y)
	map[x][y] = mapTiles.downstairs
	table.insert(mapObjects, {name = 'downstairs', x = x, y = y})
	if playerGetPrev() == 'down' then
		mapPlayerOSpawn = 'downstairs'
	end
end

--- mapMovePlayerToSObject
--- moves player to the starting spawn object.
function mapMovePlayerToSObject()
	for i = 1, # mapObjects do
		if mapObjects[i].name == mapPlayerOSpawn then
			playerMoveTo(mapObjects[i].x, mapObjects[i].y)
		end
	end
	if playerGetPrev() == 'random' then
		--- quick and dirty random tile
		while true do
			local x = math.random(1, mapWidth)
			local y = math.random(1, mapHeight)
			if map[x][y].walkThru then
				playerMoveTo(x, y)
				return
			end
		end
	end
end

--- mapGenCaveHelperIsCoordInTable
function mapGenCaveHelperIsCoordInTable(x, y, tab)
	for i = 1, # tab do
		if tab[i][1] == x and tab[i][2] == y then
			return true
		end
	end
	return false
end

--- mapGenBigRoom
--- Big room map generation.  NetHack style.
function mapGenBigRoom(w, h)
	mapInit(w, h)
	for x = 1, mapWidth do
		map[x][1] = mapTiles.wall
		map[x][mapHeight] = mapTiles.wall
	end
	for y = 1, mapHeight do
		map[1][y] = mapTiles.wall
		map[mapWidth][y] = mapTiles.wall
	end
	--- random room in center
	local x = math.random(10, w - 20)
	local y = math.random(5, h - 10)
	local ww = math.random(5, 10)
	local hh = math.random(3, 5)
	for xx = x, x + ww do
		for yy = y, y + hh do
			map[xx][yy] = mapTiles.wall
		end
	end
	gameSetRedrawAll()
end

function mapFlipLitToSeen()
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			if mapFog[x][y].lit then
				mapFog[x][y].lit = false
				mapFog[x][y].seen = true
				mapDrawTile(x, y)
			end
		end
	end
end

--- mapCalcFog
--- calculates fog with given start point and radius.
function mapCalcFog(sx, sy, radius)
	--- Set all lit tiles to be unlit and seen
	mapFlipLitToSeen()
	--- calculate fog now
	local mult = { {1, 0, 0, -1, -1, 0, 0, 1},
				   {0, 1, -1, 0, 0, -1, 1, 0},
				   {0, 1, 1, 0, 0, -1, -1, 0},
				   {1, 0, 0, 1, -1, 0, 0, -1},
				   }
	for oct = 1, 8 do
		mapCastLight(sx, sy, 1, 1.0, 0.0, radius, mult[1][oct], mult[2][oct], mult[3][oct], mult[4][oct], 0)
	end
end

--- mapCastLight
--- recursive function for mapCalcFog
function mapCastLight(cx, cy, row, start, endp, radius, xx, xy, yx, yy, id)
	if start < endp then
		return
	end
	local radius_squared = radius*radius
	for j = row, radius+1 do
		local dx, dy = -j-1, -j
		local blocked = false
		while dx <= 0 do
			dx = dx + 1
			local X, Y = cx + dx * xx + dy * xy, cy + dx * yx + dy * yy
			local l_slope, r_slope = (dx-0.5)/(dy+0.5), (dx+0.5)/(dy-0.5)
			if start < r_slope then
				--- continue
			elseif endp > l_slope then
				break
			else
				if dx*dx + dy*dy < radius_squared then
					if X > 0 and X < mapWidth and Y > 0 and Y < mapHeight and map[X][Y] then
						mapFog[X][Y].lit = true
						mapDrawTile(X, Y)
					end
				end
				if blocked then
					if X > 0 and X <= mapWidth and Y > 0 and Y <= mapHeight and not map[X][Y].seeThru then
						new_start = r_slope
						---continue
					else
						blocked = false
						start = new_start
					end
				else
					if X > 0 and X <= mapWidth and Y > 0 and Y <= mapHeight and not map[X][Y].seeThru and j < radius then
						blocked = true
						mapCastLight(cx, cy, j+1, start, l_slope, radius, xx, xy, yx, yy, id+1)
						new_start = r_slope
					end
				end
			end
		end
		if blocked then break end
	end
end

--- mapIsLit
--- returns true or false whether or not specified tile is lit
function mapIsLit(x, y)
	if mapFog[x][y].lit then
		return true
	end
	return false
end

--- mapCheckTileAt
--- returns true or false whether or not the chosen tile key
--- matchs the chosen string.
function mapCheckTileAt(x, y, tile)
	if map[x][y] == mapTiles[tile] or map[x][y].name == tile then
		return true
	end
	return false
end

--- mapSwitchDoor
--- switches a door between open and close at target tile.
function mapSwitchDoor(x, y)
	if map[x][y] == mapTiles.closeddoor or map[x][y].name == 'closeddoor' then
		map[x][y] = mapTiles.opendoor
		playerCastFog()
		gameSetRedrawAll()
	elseif map[x][y] == mapTiles.opendoor or map[x][y].name == 'opendoor' then
		map[x][y] = mapTiles.closeddoor
		playerCastFog()
		gameSetRedrawAll()
	end
end

--- mapResetFog
--- seets all fog to be unlit and unseen
function mapResetFog()
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			mapFog[x][y].seen = false
			mapFog[x][y].lit = false
		end
	end
end

--- mapDidPlayerWalkOverObject
--- If the player walked on a map object then display a message.
function mapDidPlayerWalkOverObject(x, y)
	--- Map Objects
	for i = 1, # mapObjects do
		if x == mapObjects[i].x and y == mapObjects[i].y then
			if mapObjects[i].name == 'connection' then
				messageRecieve("There is a tunnel leading to the " .. mapObjects[i].connection .. " here.")
			elseif mapObjects[i].name == 'upstairs' then
				messageRecieve("There is a staircase leading up here.")
			elseif mapObjects[i].name == 'downstairs' then
				messageRecieve("There is a staircase leading down here.")
			end
		end
	end
	--- Special Tiles
	if mapGetTileName(x, y) == 'identify' then
		messageRecieve("There is an identification stand here.")
	end
end

--- mapUseIdentificationStand
--- Uses an identification stand at passed coordinates if it exists.
--- If the stand exists, then the passed item becomes permanently identified
--- and the stand loses a charge.  If the stand has no charges then no item
--- can be identified and an appropriate message is sent to the player.
function mapUseIdentificationStand(x, y, item)
	if mapGetTileName(x, y) == 'identify' then
		if map[x][y].charge > 0 then
			if not itemIsIdentified(item) then
				map[x][y].charge = map[x][y].charge - 1
				messageRecieve("The identification stand glows blue for a moment...")
				itemAddIdentify(item)
				if map[x][y].charge == 0 then
					messageRecieve("Sparks fly and the identification stand begins to smoke.")
			else
				if item.data.idname then
					messageRecieve("The identification stand glows green for a moment...")
					messageRecieve("You have already identified this as " .. item.data.singular .. item.data.idname .. ".")
				else
					messageRecieve("The identification stand glows green for a moment...")
					messageRecieve("You have already identified this as " .. item.data.singular .. item.data.name .. ".")
				end
			end
		else
			messageRecieve("Nothing happens.")
		end
	end
end

--- mapPlaceSpecialTiles
--- Places guaranteed special tiles as defined in data/branch.lua
function mapPlaceSpecialTiles()
	local specialTiles = mapBranch[mapCurrentBranch].tiles
	for i = 1, # specialTiles do
		if mapGetCurrentFloor() == specialTiles[i].floor then
			local tile = specialTiles[i]
			local placed = false
			local x = 0
			local y = 0
			while not placed do
				--- Random coordinates or guaranteed coordinates
				if tile.x == 'random' then x = math.random(1, mapWidth) end
				if tile.y == 'random' then y = math.random(1, mapHeight) end
				if mapGetWalkThru(x, y) and map[x][y].char ~= '╫' and mapGetTileName(x, y) ~= 'downstairs' and mapGetTileName(x, y) ~= 'upstairs' then
					map[x][y] = mapTiles[tile.name]
					placed = true
				end
			end
		end
	end
end

--- Getters
function mapGetWalkThru(x, y) return map[x][y].walkThru end
function mapGetWidth() return mapWidth end
function mapGetHeight() return mapHeight end
function mapGetCurrentBranch() return mapCurrentBranch end
function mapGetCurrentFloor() return mapCurrentFloor end
function mapGetPlayerSX() return mapPlayerSX end
function mapGetPlayerSY() return mapPlayerSY end
function mapGetTile(x, y) return map[x][y] end
function mapGetTileName(x, y) return map[x][y].name end
--- setters
function mapSetCurrentBranch(arg) mapCurrentBranch = arg end
function mapSetCurrentFloor(arg) mapCurrentFloor = arg end