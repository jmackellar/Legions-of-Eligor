--- map.lua
--- Map table, tiles, and held creatures and items.

local mapStartX = 1
local mapStartY = 2

local mapWidth = 80
local mapHeight = 20
local map = { }
local mapSeen = { }
local mapEffect = { }
local mapPackSpots = { }

local mapDijkstra = { }

local mapCurrentBranch = 'Outpost'
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
	mapObjects = { }
	mapEffect = { }
	for x = 1, mapWidth do
		map[x] = { }
		mapFog[x] = { }
		mapEffect[x] = { }
		for y = 1, mapHeight do
			map[x][y] = mapTiles.floor
			mapFog[x][y] = {seen = false, lit = false}
			mapEffect[x][y] = false
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

--- mapDrawEffects
--- Draws all map effects
function mapDrawEffects()
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			mapDrawTileEffect(x, y)
		end
	end
	gameSetRedrawPlayer()
	gameSetRedrawCreature()
end

--- mapSpawnLevelPack
--- Spawns a pack of monsters that pertain to the specific level. 
--- The pack should include a lot of popcorn and 1 or 2 strong enemies
function mapSpawnLevelPack(x, y)
	--- Unique pack serial
	local serial = love.math.random(1, 10000)
	---------------------
	------ Pack Builder
	---------------------
	--- Figure out what normal creatures we can use and what rare creatures we can use
	local c = mapBranch[mapCurrentBranch].creatures 
	local r = mapBranch[mapCurrentBranch].rareCreatures
	if # c == 0 then return end --- Safety Kill Switch
	--- Decide how many creatures we want the pack to be in total
	local cMin = math.ceil(mapBranch[mapCurrentBranch].minCreatures / 5)
	local cMax = math.ceil(mapBranch[mapCurrentBranch].maxCreatures / 5)
	local total = math.random(cMin, cMax)
	--- Determine which normal creatures to use and how many of each
	local types = love.math.random(1, math.min(3, # c)) --- # of different normal monsters
	local cNums = mapGetRandomNonSameInts(types, 1, types)
	local mons = { }
	local cEach = 0
	for i = 1, # c do
		table.insert(mons, c[cNums[i]])
	end
	cEach = math.ceil(total / # mons)
	--- Determine which rare creatures to use and how many of each
	local rTypes = 0
	local rNums = { }
	local rMons = { }
	if # r > 0 then
		rTypes = love.math.random(1, math.min(2, # r))
		rNums = mapGetRandomNonSameInts(rTypes, 1, rTypes)
		for i = 1, # r do
			table.insert(rMons, r[rNums[i]])
		end
	end
	---------------------
	------- Pack Placer
	---------------------
	--- Place rare monsters first in the center of the pack
	if # rMons > 0 then
		for i = 1, # rMons do
			local sx, sy = mapClosestWalkableTileTo(x, y)
			if sx and sy then
				creatureSpawn(sx, sy, rMons[i].name)
				creatureSetSerialAt(sx, sy, serial)
			end
		end
	end
	--- Place normal creatures now around the rare monsters
	for i = 1, # mons do
		for k = 1, cEach do
			local sx, sy = mapClosestWalkableTileTo(x, y)
			if sx and sy then
				creatureSpawn(sx, sy, mons[i].name)
				creatureSetSerialAt(sx, sy, serial)
			end
		end
	end
end

--- mapGenerateCreatures
--- spawns the maps creatures.
function mapGenerateCreatures()
	creatureClearAll()
	--- Generate normal creatures.
	local c = mapBranch[mapCurrentBranch].creatures
	local cMin = mapBranch[mapCurrentBranch].minCreatures
	local cMax = mapBranch[mapCurrentBranch].maxCreatures
	local total = math.random(cMin, cMax)
	
	--- Modify total based on level depth
	--- lower depths lower total creature count
	--- Only do this for the Dungeon branch though
	if mapCurrentBranch == 'Dungeon' and mapCurrentFloor <= 3 then
		total = total - (mapCurrentFloor * -3 + 9)
	end
	
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
	--- Generate rare creatures.
	if mapCurrentBranch == 'Dungeon' and mapCurrentFloor == 1 then return end
	local c = mapBranch[mapCurrentBranch].rareCreatures
	if not c then return end
	for i = 1, # c do
		local total = math.random(c[i].min, c[i].max)
		local placed = 0
		if mapCurrentBranch == 'Dungeon' and mapCurrentFloor == 2 then 
			total = 1
		end
		while placed < total do
			local x = math.random(2, mapWidth - 1)
			local y = math.random(2, mapHeight - 1)
			if map[x][y].walkThru and playerIsTileFree(x, y) and creatureIsTileFree(x, y) then
				placed = placed + 1
				creatureSpawn(x, y, c[i].name)
			end
		end
	end
	--- Generate Packs
	if mapBranch[mapCurrentBranch].minPacks and mapBranch[mapCurrentBranch].maxPacks then
		local pNum = love.math.random(mapBranch[mapCurrentBranch].minPacks, mapBranch[mapCurrentBranch].maxPacks)
		for i = 1, pNum do
			if mapPackSpots and mapPackSpots[i] then
				mapSpawnLevelPack(mapPackSpots[i][1], mapPackSpots[i][2])
			else
				local placed = false
				while not placed do
					local x = love.math.random(2, mapWidth - 1)
					local y = love.math.random(2, mapHeight - 1)
					if map[x][y].walkThru and creatureIsTileFree(x, y) and playerIsTileFree(x, y) then
						placed = true 
						mapSpawnLevelPack(x, y)
					end
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
	me = tostring(mapCurrentBranch .. mapCurrentFloor .. "effect.lua")
	love.filesystem.newFile(m)
	love.filesystem.newFile(mf)
	love.filesystem.newFile(mo)
	love.filesystem.newFile(me)
	love.filesystem.write(m, Ser(map))
	love.filesystem.write(mf, Ser(mapFog))
	love.filesystem.write(mo, Ser(mapObjects))
	love.filesystem.write(me, Ser(mapEffect))
end

--- mapLoad
--- loads a map.  Returns true if loaded, false if no map could be loaded.
function mapLoad()
	mapLoadCreatures()
	mapLoadItems()
	m = tostring(mapCurrentBranch .. mapCurrentFloor .. ".lua")
	mf = tostring(mapCurrentBranch .. mapCurrentFloor .. "fog.lua")
	mo = tostring(mapCurrentBranch .. mapCurrentFloor .. "objects.lua")
	me = tostring(mapCurrentBranch .. mapCurrentFloor .. "effect.lua")
	if love.filesystem.exists(m) and love.filesystem.exists(mf) and love.filesystem.exists(mo) and love.filesystem.exists(me) then
		local c1 = love.filesystem.load(m)
		local c2 = love.filesystem.load(mf)
		local c3 = love.filesystem.load(mo)
		local c4 = love.filesystem.load(me)
		map = c1()
		mapFog = c2()
		mapObjects = c3()
		mapEffect = c4()
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
	if s == 'yes' then mapSave() playerSave() end
	mapCurrentFloor = mapCurrentFloor + dy
	mapObjects = { }
	mapPackSpots = { }
	if not mapLoad() then
		--- a map for this level doesnt already exist, generate a new one
		if mapBranch[mapCurrentBranch].gen == 'mapGenCave' then
			mapGenCave(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenDungeon' then
			mapGenDungeon(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenJails' then
			mapGenJails(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenBSP' then
			mapGenBSP(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenGrave' then
			mapGenGrave(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenTown' then
			mapGenTown(mapWidth, mapHeight)
		elseif mapBranch[mapCurrentBranch].gen == 'mapGenHallway' then
			mapGenHallway(mapWidth, mapHeight)
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
	mapGenWanderDijkstras(3)
	playerCastFog()
	gameSetRedrawAll()
end

--- mapChangeBranch
--- changes map branch
function mapChangeBranch(branch, save, debug)
	local s = save or true
	local d = debug or false
	if s then mapSave() end
	if d then playerSetPrev('random') end
	mapCurrentBranch = branch
	mapCurrentFloor = 0
	mapChangeFloor(1, false)
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

--- mapAddTileEffect
--- Adds a passed effect with type and turn count to passed tile coordinates.
function mapAddTileEffect(x, y, efct)
	--- Create a new effect table passed on the passed table
	--- this is because we want all map tiles to have their own unique 
	--- table, and when declaring new tables that equal an old table
	--- Lua doesn't duplicate the table, it points the new one to the old one.
	local effect = { }
	for k,v in pairs(efct) do
		effect[k] = v
	end
	if x > 1 and x < mapWidth and y > 1 and y < mapHeight then
		mapEffect[x][y] = effect
		gameSetRedrawAll()
	end
end

--- mapUpdateTileEffect
--- Updates tile effects every turn.
function mapUpdateTileEffect()
	local msg = { }
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			--- If a mapTile has an effect table then update
			--- all the effects in that table.
			if mapEffect[x][y] then
			
				--- Tick turn counter
				mapEffect[x][y].turn = mapEffect[x][y].turn - 1
				
				--- If effects time has run out playe end message and
				--- then delete the effect
				if mapEffect[x][y].turn <= 0 then
					--- Add the end message to the msg table if that
					--- message isn't already in the table
					local intable = false
					for i = 1, # msg do
						if msg[i] == mapEffect[x][y].endmsg then
							intable = true
						end
					end
					if not intable then
						table.insert(msg, mapEffect[x][y].endmsg)
					end
					--- Now remove the effect
					mapEffect[x][y] = false
					
				--- The effect still exists, if the player is on
				--- the effected tile then take damage and display
				--- hurt message.
				else
					if playerGetX() == x and playerGetY() == y then
						messageRecieve(mapEffect[x][y].hurtmsg)
						playerRecieveDamage(mapEffect[x][y].dam)
					end
				end
			end
		end
	end
	--- Send all messages from the msg table to the message handler
	for i = 1, # msg do
		messageRecieve(msg[i])
	end
end

--- mapDrawTileEffect
--- Draws targeted tile's map effect if one exists.
function mapDrawTileEffect(x, y)
	if mapEffect[x][y] then
		local xx = mapStartX + (x - 1)
		local yy = mapStartY + (y - 1)
		print("TRUE " .. x .. " " .. y)
		consolePut({x = xx, y = yy, char = mapEffect[x][y].char, backColor = mapEffect[x][y].backColor, textColor = mapEffect[x][y].textColor})
	end
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
			--- If mapTile is currently visible to the player then draw the tile lit up
			consolePut({x = xx, y = yy, char = map[x][y].char, backColor = map[x][y].backColor, textColor = tC})
			if not map[x][y].noGore then mapDrawBlood(x, y, true) end
		elseif mapFog[x][y].seen then
			local tc = {tC[1], tC[2], tC[3], 100}
			consolePut({x = xx, y = yy, char = map[x][y].char, backColor = map[x][y].backColor, textColor = tc})
			if not map[x][y].noGore then mapDrawBlood(x, y, false) end
		else
			consolePut({x = xx, y = yy, char = ' ', backColor = {0, 0, 0, 255}, textColor = {0, 0, 0, 255}})
		end
	else
		local tC = map[x][y].textColor
		consolePut({x = xx, y = yy, char = map[x][y].char, backColor = map[x][y].backColor, textColor = tC})
	end
end

--- mapDrawBlood
--- Draws the blood and gore of the passed tile.
function mapDrawBlood(x, y, lit)
	local bC = {0, 0, 0, 255}
	if map[x][y].blood then
		local a = 255
		local blood = map[x][y].blood
		local rgbval = math.min(math.ceil(42.5 * blood.val), 255)
		local negval = rgbval * -1
		if not lit then a = 100 end
		local BC = map[x][y].backColor
		local tC = map[x][y].textColor
		local tc = {tC[1], tC[2], tC[3], a}
		local vals = {blood.color[1], blood.color[2], blood.color[3]}
		for i = 1, # vals do
			if BC[i] < vals[i] then
				bC[i] = BC[i] + rgbval 
				if bC[i] > vals[i] then bC[i] = vals[i] end
			elseif BC[i] > vals[i] then
				bC[i] = BC[i] - rgbval 
				if bC[i] < vals[i] then bC[i] = vals[i] end
			end
		end
		bC[4] = 255
		consolePut({x = mapStartX + (x - 1), y = mapStartY + (y-1), char = map[x][y].char, backColor = bC, textColor = tc})
	end
	if map[x][y].blood and map[x][y].blood.corpse then
		if lit then a = 255 end
		if not lit then a = 100 end
		consolePut({char = map[x][y].blood.corpse, x = mapStartX + (x - 1), y = mapStartY + (y-1), backColor = bC, textColor = {0, 0, 0, a}})
	end
end

--- mapGenHallway
--- Hallways between some branches.
function mapGenHallway(w, h)
	mapInit(w, h)

	--- Fill map with blank tiles
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			map[x][y] = mapTiles.blank
		end
	end

	--- Make Hallway
	for x = 30, 50 do
		for y = 8, 14 do
			map[x][y] = mapTiles.floor
			if x < 31 or x > 49 or y < 9 or y > 13 then
				map[x][y] = mapTiles.smoothwall
			end
		end
	end

	for x = 37, 43 do
		for y = 4, 8 do
			map[x][y] = mapTiles.floor
			if x < 38 or x > 42 or y < 5 then
				map[x][y] = mapTiles.smoothwall
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
end

--- mapGenTown
--- Overworld town hub.
function mapGenTown(w, h)
	mapInit(w, h)

	--- Grass
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			map[x][y] = mapTiles.grass
		end
	end
	
	--- Outside Fence
	for x = 1, mapWidth do
		map[x][1] = mapTiles.fence
		map[x][mapHeight - 1] = mapTiles.fence
	end
	for y = 1, mapHeight do
		map[1][y] = mapTiles.blank
		map[2][y] = mapTiles.fence
		map[mapWidth - 1][y] = mapTiles.fence
	end

	--- Mountain range
	for x = 2, mapWidth do
		local yEnd = ( (1/140) * ((x-30)^2) ) + 1    --- //What the fuck?
		for y = 1, yEnd do
			y = math.floor(y)
			if y >= 1 and y < mapHeight then
				map[x][y] = mapTiles.wall
			end
		end
	end

	--- Cavern
	for x = 70, 77 do
		for y = 4, 8 do
			map[x][y] = mapTiles.floor
		end
	end
	for x = 66, 70 do
		map[x][4] = mapTiles.floor
		map[x][5] = mapTiles.floor
	end
	for x = 60, 66 do
		map[x][5] = mapTiles.floor
		map[x][6] = mapTiles.floor
	end
	for x = 58, 61 do
		map[x][6] = mapTiles.floor
		map[x][7] = mapTiles.floor
	end
	map[67][6] = mapTiles.floor

	--- Water
	for x = 2, mapWidth do
		for y = 18, mapHeight do
			if x <= 6 then
				map[x][y-1] = mapTiles.water
			end
			map[x][y] = mapTiles.water
			if x > 12 and x < 74 and y == 18 then
				map[x][y] = mapTiles.grass
			end		
		end
	end

	--- Church
	for x = 8, 24 do
		for y = 8, 14 do
			map[x][y] = mapTiles.floor
			if x < 9 or x > 23 or y < 9 or y > 13 then
				map[x][y] = mapTiles.smoothwall
			end
		end
	end
	--- Big Shortcut
	for x = 4, 8 do
		for y = 9, 13 do
			map[x][y] = mapTiles.floor
			if x < 5 or x > 7 or y < 10 or y > 12 then
				map[x][y] = mapTiles.smoothwall
			end
		end
	end
	--- Shortcut #1
	map[9][7] = mapTiles.smoothwall
	map[9][6] = mapTiles.smoothwall
	map[10][6] = mapTiles.smoothwall
	map[11][6] = mapTiles.smoothwall
	map[11][7] = mapTiles.smoothwall
	map[10][7] = mapTiles.floor
	map[10][8] = mapTiles.closeddoor
	--- Shortcut #2
	map[13][7] = mapTiles.smoothwall
	map[13][6] = mapTiles.smoothwall
	map[14][6] = mapTiles.smoothwall
	map[15][6] = mapTiles.smoothwall
	map[15][7] = mapTiles.smoothwall
	map[14][7] = mapTiles.floor
	map[14][8] = mapTiles.closeddoor
	--- Shortcut #3
	map[17][7] = mapTiles.smoothwall
	map[17][6] = mapTiles.smoothwall
	map[18][6] = mapTiles.smoothwall
	map[19][6] = mapTiles.smoothwall
	map[19][7] = mapTiles.smoothwall
	map[18][7] = mapTiles.floor
	map[18][8] = mapTiles.closeddoor
	--- Shortcut #4
	map[21][7] = mapTiles.smoothwall
	map[21][6] = mapTiles.smoothwall
	map[22][6] = mapTiles.smoothwall
	map[23][6] = mapTiles.smoothwall
	map[23][7] = mapTiles.smoothwall
	map[22][7] = mapTiles.floor
	map[22][8] = mapTiles.closeddoor
	--- Church front door
	local frontdoor = {}
	for k,v in pairs(mapTiles.closeddoor) do
		frontdoor[k] = v 
	end
	frontdoor.locked = 'Church Key'
	map[24][11] = frontdoor
	--- Bigshortcut door
	map[8][11] = mapTiles.closeddoor

	--- House #1
	for x = 31, 36 do
		for y = 3, 7 do
			map[x][y] = mapTiles.floor
			if x < 32 or x > 35 or y < 4 or y > 6 then
				map[x][y] = mapTiles.smoothwall
			end
		end
	end
	local door = { }
	for k,v in pairs(mapTiles.closeddoor) do
		door[k] = v
	end
	door.locked = 'House Key'
	map[34][7] = door

	--- House #2
	for x = 55, 60 do
		for y = 12, 16 do
			map[x][y] = mapTiles.floor
			if x < 56 or x > 59 or y < 13 or y > 15 then
				map[x][y] = mapTiles.smoothwall
			end
		end
	end
	map[55][14] = mapTiles.closeddoor

	mapMovePlayerToSObject()
	playerCastFog()
	---mapGenerateCreatures()
	itemGenerate()
	mapPlaceSpecialTiles()
	mapPlaceConnections()
	gameSetRedrawAll()
end

--- mapGenGrave
--- Graveyard with boss holding the Rusted Key
function mapGenGrave(w, h)
	mapInit(w, h)
	
	--- Grass
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			map[x][y] = mapTiles.grass
		end
	end
	
	--- Outside Fence
	for x = 1, mapWidth do
		map[x][1] = mapTiles.fence
		map[x][mapHeight - 1] = mapTiles.fence
	end
	for y = 1, mapHeight do
		map[1][y] = mapTiles.fence
		map[mapWidth - 1][y] = mapTiles.fence
	end
	
	--- tombstones
	for x = 6, mapWidth - 7, 3 do
		for y = 5, mapHeight - 5, 3 do
			if love.math.random(1, 100) <= 65 then
				map[x][y] = mapTiles.tombstone
				map[x][y+1] = mapTiles.floor
			end
		end
	end
	
	--- trees
	local placed = 0
	while placed < 15 do
		local x = love.math.random(4, mapWidth - 4)
		local y = love.math.random(4, mapHeight - 4)
		if map[x][y] == mapTiles.grass then
			map[x][y] = mapTiles.deadtree
			placed = placed + 1
		end
	end
	
	--- Central tomb
	---	###...###
	--- #.......#
	--- .........
	--- .........
	--- #.......#
	--- ###...###
	local sx = love.math.random(21, 55)
	local sy = love.math.random(6, 9)
	local w = 8
	local h = 5
	for x = sx - 1, sx + w + 1 do
		for y = sy - 1, sy + h + 1 do
			map[x][y] = mapTiles.grass
		end
	end
	map[sx+4][sy+2] = mapTiles.smoothwall
	map[sx+4][sy+3] = mapTiles.floor
	for x = sx, sx + 2 do
		map[x][sy] = mapTiles.fence
		map[x][sy+h] = mapTiles.fence
	end
	map[sx][sy+1] = mapTiles.fence
	map[sx][sy+4] = mapTiles.fence
	for x = sx+6, sx+w do
		map[x][sy] = mapTiles.fence
		map[x][sy+h] = mapTiles.fence
	end
	map[sx+w][sy+1] = mapTiles.fence
	map[sx+w][sy+4] = mapTiles.fence
	
	--- inner fence
	for x = 5, mapWidth - 6 do
		if x < 30 or x > 50 then
			map[x][4] = mapTiles.fence
			map[x][mapHeight - 4] = mapTiles.fence
		end
	end
	for y = 4, mapHeight - 4 do
		if y < 7 or y > 13 then
			map[5][y] = mapTiles.fence
			map[mapWidth - 5][y] = mapTiles.fence
		end
	end
	
	--- Stairway connection
	local stairs = {{3, 10}, {40, 3}, {40, 18}, {77, 10}}
	local dice = love.math.random(1, 4)
	--- name connection drop x y
	map[stairs[dice][1]][stairs[dice][2]] = mapTiles.connection
	table.insert(mapObjects, {name = 'connection', connection = 'Caves', drop = 4, x = stairs[dice][1], y = stairs[dice][2]})
	
	mapMovePlayerToSObject()
	playerCastFog()
	mapGenerateCreatures()
	itemGenerate()
	mapPlaceSpecialTiles()
	gameSetRedrawAll()
end

--- mapGenBSP
--- Rooms directly connected to each other.  No corridors.
function mapGenBSP(w, h)
	mapInit(w, h)
	
	--- Fill map with walls
	for x = 1, mapWidth do
		for y = 1, mapHeight do
			map[x][y] = mapTiles.smoothwall
		end
	end
	
	local make = true
	local wall = 1
	local base = 1
	local minw = 9
	local maxw = 13
	local minh = 7
	local maxh = 7
	local door = { }
	local rooms = { }
	local w = math.random(minw, maxw)
	local h = math.random(minh, maxh)
	local x = math.random(10, 70 - w)
	local y = math.random(3, 17 - h)
	local tries = 0
	local dir = " "

	--- Create first room
	table.insert(rooms, {x = x, y = y, w = w, h = h})
	for xx = x, x + w do
		for yy = y, y + h do
			map[xx][yy] = mapTiles.floor
		end
	end
	for xx = x, x + w do
		if map[xx][y] == mapTiles.floor then map[xx][y] = mapTiles.smoothwall end
		if map[xx][y+h] == mapTiles.floor then map[xx][y+h] = mapTiles.smoothwall end
	end
	for yy = y, y + h do
		if map[x][yy] == mapTiles.floor then map[x][yy] = mapTiles.smoothwall end
		if map[x+w][yy] == mapTiles.floor then map[x+w][yy] = mapTiles.smoothwall end
	end
	print("adding room #" .. #rooms+1 .. " " .. dir .. " at (" .. x .. "," .. y .. ") with W:" .. w .. ", H:" ..h)
	
	while # rooms < 12 do
		tries = tries + 1
		if tries >= 100 then break end
		make = true
		door = false
		--- Pick a random base room
		base = math.random(1, # rooms)
		--- random room dimensions
		w = math.random(minw, maxw)
		h = math.random(minh, maxh)
		--- pick a wall from the base room for the new room to
		--- be adjacent to
		wall = math.random(1, 2)	--- 1 = horizontal wall, 2 = vertical wall
		if wall == 1 then
			--- slide room around a little
			x = math.random(rooms[base].x - 2, rooms[base].x + rooms[base].w - 3)
			--- pick if the top or bottom wall
			if math.random(1, 2) == 1 then	--- top
				dir = 'top'
				y = rooms[base].y - h
				door = {x = x+2, y = y+h}
			else
				dir = 'bot'
				y = rooms[base].y + rooms[base].h
				door = {x = x+2, y = y}
			end
		elseif wall == 2 then
			--- slide room around a little
			y = math.random(rooms[base].y - 2, rooms[base].y + rooms[base].h - 3)
			--- pick if right or left wall
			if math.random(1, 2) == 1 then --- left
				dir = 'left'
				x = rooms[base].x - w
				door = {x = x+w, y = y+2}
			else
				dir = 'right'
				x = rooms[base].x + rooms[base].w
				door = {x = x, y = y+2}
			end
		end
		--- check if the room in question is not outside the map
		if x > 2 and x + w < mapWidth - 1 and y > 2 and y + h < mapHeight - 1 then
			--- check for collisions with other rooms
			for i = 1, # rooms do
				if rooms[i] ~= rooms[base] then
					if x <= rooms[i].x + rooms[i].w and 
					   x + w >= rooms[i].x and
					   y <= rooms[i].y + rooms[i].h and
					   y + h >= rooms[i].y then
					   make = false
					end
				end
			end
		else
			make = false
		end
		--- If we can make the room then do so
		if make then
			for xx = x, x + w do
				for yy = y, y + h do
					map[xx][yy] = mapTiles.floor
				end
			end
			for xx = x, x + w do
				if map[xx][y] == mapTiles.floor then map[xx][y] = mapTiles.smoothwall end
				if map[xx][y+h] == mapTiles.floor then map[xx][y+h] = mapTiles.smoothwall end
			end
			for yy = y, y + h do
				if map[x][yy] == mapTiles.floor then map[x][yy] = mapTiles.smoothwall end
				if map[x+w][yy] == mapTiles.floor then map[x+w][yy] = mapTiles.smoothwall end
			end
			if door then
				map[door.x][door.y] = mapTiles.closeddoor
			end
			print("adding room #" .. #rooms+1 .. " " .. dir .. " at (" .. x .. "," .. y .. ") with W:" .. w .. ", H:" ..h)
			table.insert(rooms, {x = x, y = y, w = w, h = h})
		end
	end
	
	--- Boundary walls
	for x = 1, mapWidth do
		map[x][1] = mapTiles.smoothwall
		map[x][mapHeight] = mapTiles.smoothwall
	end
	for y = 1, mapHeight do
		map[1][y] = mapTiles.smoothwall
		map[mapWidth][y] = mapTiles.smoothwall
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
	
	mapMovePlayerToSObject()
	playerCastFog()
	mapGenerateCreatures()
	itemGenerate()
	mapPlaceSpecialTiles()
	mapPlaceConnections()
	gameSetRedrawAll()
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
		table.insert(mapPackSpots, {math.floor(rooms[i].x + rooms[i].w / 2), math.floor(rooms[i].y + rooms[i].h / 2)})
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
	
	mapPlaceSpecialTiles()
	mapPlaceConnections()
	
	--- If last floor of dungeons then place locked
	--- room around the connection leading to storehouse
	if mapCurrentFloor == mapBranch[mapCurrentBranch].floors then
		for i = 1, # mapObjects do
			if mapObjects[i].connection == 'Hallway' then
				local x = mapObjects[i].x
				local y = mapObjects[i].y
				for xx = x - 2, x + 2 do
					if xx > x - 2 and xx < x + 2 then
						map[xx][y-1] = mapTiles.smoothwall
						map[xx][y+1] = mapTiles.smoothwall
					end
					map[xx][y-2] = mapTiles.floor
					map[xx][y+2] = mapTiles.floor
					if map[xx][y-3] == mapTiles.blank then map[xx][y-3] = mapTiles.smoothwall	end
					if map[xx][y+3] == mapTiles.blank then map[xx][y+3] = mapTiles.smoothwall end
				end
				for yy = y - 2, y + 2 do
					if yy > y - 2 and yy < y + 2 then
						map[x-1][yy] = mapTiles.smoothwall
						map[x+1][yy] = mapTiles.smoothwall
					end
					map[x-2][yy] = mapTiles.floor
					map[x+2][yy] = mapTiles.floor
					if map[x-3][yy] == mapTiles.blank then map[x-3][yy] = mapTiles.smoothwall end
					if map[x+3][yy] == mapTiles.blank then map[x+3][yy] = mapTiles.smoothwall end
				end
				map[x-3][y-3] = mapTiles.smoothwall
				map[x-3][y+3] = mapTiles.smoothwall
				map[x+3][y-3] = mapTiles.smoothwall
				map[x+3][y+3] = mapTiles.smoothwall
				local door = { }
				for k,v in pairs(mapTiles.closeddoor) do
					door[k] = v
				end
				map[x][y+1] = door
				map[x][y+1].locked = 'Rusted Key'
			end
		end
	end

	mapMovePlayerToSObject()
	mapGenerateCreatures()
	itemGenerate()
	playerCastFog()
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
				local x = connections[i].x or math.random(3, mapWidth - 2)
				local y = connections[i].y or math.random(3, mapHeight - 2)
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
	elseif playerGetPrev() == 'spawn' then
		local x = 43
		local y = 13
		playerMoveTo(x, y)
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
						mapFog[X][Y].seen = true
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
		--- check if the door is locked or not
		if not map[x][y].locked or (itemIsInInventory(map[x][y].locked)) then
			if map[x][y].locked then
				itemRemoveFromInventory(map[x][y].locked)
				messageRecieve("You unlock the door using the " .. map[x][y].locked .. ".")
				map[x][y].locked = false
			end
			messageRecieve("You open the door.")
			map[x][y] = mapTiles.opendoor
			playerCastFog()
			gameSetRedrawAll()
		else
			messageRecieve("The door is locked by a " .. map[x][y].locked .. ".")
		end
	elseif map[x][y] == mapTiles.opendoor or map[x][y].name == 'opendoor' then
		messageRecieve("You closed the door.")
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
	elseif mapGetTileName(x, y) == 'tablet' then
		messageRecieve("There is a tablet here with a message etched on it.")
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
				end
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
	if not specialTiles then return end
	for i = 1, # specialTiles do
		if mapGetCurrentFloor() == specialTiles[i].floor then
			local tile = specialTiles[i]
			local placed = false
			local x = 0
			local y = 0
			while not placed do
				--- Random coordinates or guaranteed coordinates
				if tile.x == 'random' then x = math.random(1, mapWidth) else x = tile.x end
				if tile.y == 'random' then y = math.random(1, mapHeight) else y = tile.y end
				if mapGetWalkThru(x, y) and map[x][y].char ~= '╫' and mapGetTileName(x, y) ~= 'downstairs' and mapGetTileName(x, y) ~= 'upstairs' then
					local t = { }
					for k,v in pairs(mapTiles[tile.name]) do
						t[k] = v
					end
					if tile.msg then t.msg = tile.msg end
					map[x][y] = t
					placed = true
				end
			end
		end
	end
end

--- mapIsCreatureInVision
--- Returns true if a lit tile has a creature on it.  False if not.
function mapIsCreatureInVision(x, y)
	for xx = x - playerGetViewRadius(), x + playerGetViewRadius() do
		for yy = y - playerGetViewRadius(), y + playerGetViewRadius() do
			if xx > 1 and yy > 1 and xx < mapWidth and yy < mapHeight then
				if mapFog[xx][yy] and mapFog[xx][yy].lit and not creatureIsTileFree(xx, yy) then
					return true
				end
			end
		end
	end
	return false
end

--- mapCreateDijkstra
--- Creates a dijkstra pathfinding map for passed coordinates
function mapCreateDijkstra(x, y)
	--- Set up initial pathfinding map state
	local path = { }
	for x = 1, mapWidth do
		path[x] = { }
		for y = 1, mapHeight do
			path[x][y] = 125
		end
	end
	path[x][y] = 0
	
	--- Iterate through each map cell. If the lowest value neighbour is 2 lower
	--- than the cell then set it to be 1 higher than the lowest value neighbour.
	--- Repeat until no changes are further made. Ignore all wall tiles.
	local change = true
	while change do
		change = false
		for x = 2, mapWidth - 1 do
			for y = 2, mapHeight - 1 do
				if map[x][y].walkThru or map[x][y].name ==	'closeddoor' then
					local lowest = 125
					--- Check all neighbouring tiles
					lowest = math.min(lowest, path[x-1][y-1])
					lowest = math.min(lowest, path[x][y-1])
					lowest = math.min(lowest, path[x+1][y-1])
					lowest = math.min(lowest, path[x-1][y])
					lowest = math.min(lowest, path[x+1][y])
					lowest = math.min(lowest, path[x-1][y+1])
					lowest = math.min(lowest, path[x][y+1])
					lowest = math.min(lowest, path[x+1][y+1])
					--- Change current value if 2 or higher than lowest
					if lowest + 2 <= path[x][y] then
						path[x][y] = lowest + 1
						change = true
					end
				end
			end
		end
	end
	
	--- Pass that shit back
	return path
end

--- mapGenWanderDijkstras
--- Generates random dijkstra maps for wandering AI
function mapGenWanderDijkstras(amnt)
	local dijks = { }
	while # dijks < amnt do
		local x = math.random(1, mapWidth)
		local y = math.random(1, mapHeight)
		if map[x][y].walkThru then
			table.insert(dijks, mapCreateDijkstra(x, y))
		end
	end
	table.insert(dijks, playerGetX(), playerGetY())
	for k,v in ipairs(dijks) do
		table.insert(mapDijkstra, v)
	end
end

--- mapNewDijkstra
--- Creates new dijkstra map with passed coordinates
function mapNewDijkstra(x, y)
	table.insert(mapDijkstra, mapCreateDijkstra(x, y))
end

--- mapGetRandomDijkstra
--- Returns a random dijkstra path map
function mapGetRandomDijkstra()
	local path = mapDijkstra[math.random(1, # mapDijkstra)]
	return path
end

--- mapGetRandomNonSameInts
--- Rolls num numbers between min and max that dont match
function mapGetRandomNonSameInts(num, min, max)
	local n = { }
	repeat
		local i = love.math.random(min, max)
		if # n == 0 then 
			table.insert(n, i)
		else
			local place = true
			for k = 1, # n do
				if n == i then 
					place = false
				end
			end
			if place then
				table.insert(n, i)
			end
		end
	until # n == num
	return n
end

--- mapClosestWalkableTileTo
--- Finds the closest tile to the passed coordinates that is walkable, 
--- and doesn't have a creature or player on that tile.
function mapClosestWalkableTileTo(x, y)
	local xx = x
	local yy = y
	local r = 1
	while true do
		for xx = x - r, x + r do
			for yy = y - r, y + r do
				if map[xx][yy].walkThru then
					if creatureIsTileFree(xx, yy) and playerIsTileFree(xx, yy) then
						return xx, yy
					end
				end
			end
		end
		r = r + 1
		if r > 40 then
			return false
		end
	end
end

--- mapCreatureSpawn
--- Will randomly create creatures in the level 
function mapCreatureSpawn()
	if mapBranch[mapCurrentBranch].maxCreatures == 0 then return end
	if love.math.random(1, 100) <= 2 and creatureGetTotalCreatures() < 15 then
		local placed = false
		local c = mapBranch[mapCurrentBranch].creatures[love.math.random(1, # mapBranch[mapCurrentBranch].creatures)]
		local x = love.math.random(2, mapWidth - 1)
		local y = love.math.random(2, mapHeight - 1)
		if map[x][y].walkThru and creatureIsTileFree(x, y) and not mapFog[x][y].lit then
			placed = true
			creatureSpawn(x, y, c.name)
		end
	end
end

--- mapAddCorpse
--- Adds a corpse to the map passed on passed values
function mapAddCorpse(x, y, char, color)
	local tile = { }
	for k,v in pairs(map[x][y]) do
		tile[k] = v 
	end
	if not tile.blood then
		tile['blood'] = {val = 4, corpse = char, color = color} 
	else
		tile.blood.corpse = char
		tile.blood.color = color
		if tile.blood.val < 4 then
			tile.blood.val = 4
		end
	end
	map[x][y] = tile
end

--- mapSplashBlood
--- Spalshes blood on the ground in target direction
function mapSplashBlood(startX, startY, dX, dY, amnt, color)
	local dist = math.ceil(6 * (amnt / 100))
	local splat = 4
	local maxSplats = math.ceil(10 * (amnt / 100))
	local drawX = startX
	local drawY = startY
	local splatmult = dist 
	local var = 45
	local angle = 0
	if not color then
		color = {255, 0, 0}
	end
	if dX == 1 and dY == 0 then angle = 0 end
	if dX == -1 and dY == 0 then angle = 180 end
	if dX == -1 and dY == -1 then angle = 225 end
	if dX == -1 and dY == 1 then angle = 130 end
	if dX == 1 and dY == -1 then angle = 315 end
	if dX == 1 and dY == 1 then angle = 45 end
	if dX == 0 and dY == -1 then angle = 270 end
	if dX == 0 and dY == 1 then angle = 90 end
	mapTileBloodSplash(drawX, drawY, 1, color)
	for i = 1, maxSplats do
		drawX = startX + 0.5
		drawY = startY + 0.5
		local variancy = 0
		if i > 1 then
			variancy = love.math.random(var * -1, var)
			print(variancy)
		end
		angle = angle + variancy
		for range = 1, (love.math.random(1, dist)) do
			drawX = drawX + math.cos(angle * (math.pi / 180))
			drawY = drawY + math.sin(angle * (math.pi / 180))
			if not map[math.floor(drawX)][math.floor(drawY)].walkThru then break end
		end
		if drawX > 0 and drawY > 0 and drawX <= mapWidth and drawY <= mapHeight then
			mapTileBloodSplash(math.floor(drawX), math.floor(drawY), math.max(1, splat - i), color)
		end
	end
end

--- mapTileBloodSplash
function mapTileBloodSplash(drawX, drawY, amnt, color)
	local tile = { }	
	for k,v in pairs(map[drawX][drawY]) do
		tile[k] = v 
	end
	if not tile.blood then
		tile['blood'] = {val = math.min(6, amnt), corpse = false, color = color}
	else
		tile.blood.val = math.min(6, tile.blood.val + amnt)
	end
	map[drawX][drawY] = tile
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
function mapGetTileSeen(x, y) return mapFog[x][y].seen end
function mapGetTileLit(x, y) return mapFog[x][y].lit end
--- setters
function mapSetCurrentBranch(arg) mapCurrentBranch = arg end
function mapSetCurrentFloor(arg) mapCurrentFloor = arg end