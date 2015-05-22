--- debugtools.lua
--- Debug menu to toggle debug settings on or off,
--- and other debug tools

local debugMenuParent = { 'Flags', 'Map Movement', 'Spawn Creature' }
local debugMenuFlags = { {'debugDrawCellBorders', false}, {'debugQuickKill', true}, {'debugDisableFog', false}, {'godMode', false} }
local debugMapMovement = { 'New Seed', 'Floor -1', 'Floor +1', 'Location: Outpost', 'Location: Graves', 'Location: Hallway', }
local debugMenuSpawn = { 'Clear Creatures', 'Level Pack' }

local debugMenuDir = 'parent'
local debugMenuOpen = false

local debugMenuCursor = 1

function debugtoolsKeypressed(key)
	--- toggle menu open or close
	if key == 'f1' then
		if debugMenuOpen then 
			debugMenuOpen = false 
		else 
			debugMenuOpen = true 
			debugMenuCursor = 1
			debugMenuDir = 'parent'
		end
	end
	
	if debugMenuOpen then
	
		if key == 'up' or key == 'kp8' or key == 'k' then
			debugMenuCursor = debugMenuCursor - 1
			if debugMenuCursor < 1 then debugMenuCursor = 1 end
		elseif key == 'down' or key == 'kp2' or key == 'j' then
			debugMenuCursor = debugMenuCursor + 1
			debugCursorBelowItemCheck()
		end
	
		if key == 'return' or key == 'kpenter' then
			
			--- Parent directory
			if debugMenuDir == 'parent' then
				if debugMenuParent[debugMenuCursor] then
					local choice = debugMenuParent[debugMenuCursor]
					if choice == 'Flags' then
						debugMenuDir = 'flags'
						debugMenuCursor = 1
					elseif choice == 'Spawn Creature' then
						debugMenuDir = 'spawn'
						debugMenuCursor = 1
					elseif choice == 'Map Movement' then
						debugMenuDir = 'mapmovement'
						debugMenuCursor = 1
					end
				end
			
			--- flags directory
			elseif debugMenuDir == 'flags' then
				if debugMenuFlags[debugMenuCursor] then
					local choice = debugMenuFlags[debugMenuCursor]
					if choice[1] == 'debugDrawCellBorders' then
						if debugDrawCellBorders then
							debugDrawCellBorders = false
							choice[2] = false
						else
							debugDrawCellBorders = true
							choice[2] = true
						end
						consoleRedraw()
					elseif choice[1] == 'debugQuickKill' then
						if debugQuickKill then
							debugQuickKill = false
							choice[2] = false
						else
							debugQuickKill = true
							choice[2] = true
						end
					elseif choice[1] == 'debugDisableFog' then
						if debugDisableFog then
							debugDisableFog = false
							choice[2] = false
							gameSetRedrawAll()
						else
							debugDisableFog = true
							choice[2] = true
							gameSetRedrawAll()
						end
					elseif choice[1] == 'godMode' then
						if playerGetGodMode() then 
							choice[2] = false
							playerSetGodMode(false)
						else
							choice[2] = true
							playerSetGodMode(true)
						end
					end
				end
				
			--- Spawn directory
			elseif debugMenuDir == 'spawn' then
				if debugMenuSpawn[debugMenuCursor] then
					local choice = debugMenuSpawn[debugMenuCursor]
					if choice == 'Level Pack' then
						mapSpawnLevelPack(playerGetX(), playerGetY(), 5)
					elseif choice == 'Clear Creatures' then
						creatureClearAll()
						gameSetRedrawAll()
					end
				end
				
			--- Map movement directory
			elseif debugMenuDir == 'mapmovement' then
				if debugMapMovement[debugMenuCursor] then
					local choice = debugMapMovement[debugMenuCursor]
					if choice == 'Floor +1' then
						mapChangeFloor(1)
					elseif choice == 'Floor -1' then
						mapChangeFloor(-1)
					elseif string.sub(choice, 1, 10) == 'Location: ' then
						mapChangeBranch(string.sub(choice, 11), true, true)
					end
				end
				
			end
			
		end
	end
end

--- debugCursorBelowItemCheck
--- checks if the debug menu cursor is lower than the lowest menu option.
--- If so then the cursor is moved up to the lowest option.
function debugCursorBelowItemCheck()
	local move = false
	local index = 0
	if debugMenuDir == 'parent' then
		if debugMenuCursor > # debugMenuParent then
			move = true
			index = # debugMenuParent
		end
	elseif debugMenuDir == 'flags' then
		if debugMenuCursor > # debugMenuFlags then
			move = true
			index = # debugMenuFlags
		end
	elseif debugMenuDir == 'mapgen' then
		if debugMenuCursor > # debugMenuMapGen then
			move = true
			index = # debugMenuMapGen
		end
	elseif debugMenuDir == 'spawn' then
		if debugMenuCursor > # debugMenuSpawn then
			move = true
			index = # debugMenuSpawn
		end
	elseif debugMenuDir == 'mapmovement' then
		if debugMenuCursor > # debugMapMovement then
			move = true
			index = # debugMapMovement
		end
	end
	if move then
		debugMenuCursor = index
	end
end

function debugtoolsDraw()
	if debugMenuOpen then
		love.graphics.setColor(35, 35, 35, 255)
		love.graphics.rectangle('fill', 0, 0, 350, 200)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle('line', 4, 4, 342, 192)
		
		--- parent directory
		if debugMenuDir == 'parent' then
			for i = 1, # debugMenuParent do
				love.graphics.setColor(255, 255, 255, 255)
				if debugMenuCursor == i then 
					debugtoolsDrawCursor() 
					love.graphics.setColor(0, 0, 0, 255)
				end
				love.graphics.print(debugMenuParent[i], 16, 10 + (i-1)*14)
				love.graphics.setColor(255, 255, 255, 255)
			end
		end
		
		--- flags directory
		if debugMenuDir == 'flags' then
			for i = 1, # debugMenuFlags do
				local flag = debugMenuFlags[i]
				love.graphics.setColor(255, 255, 255, 255)
				if debugMenuCursor == i then 
					debugtoolsDrawCursor() 
					love.graphics.setColor(0, 0, 0, 255)
				end
				love.graphics.print(flag[1] .. " : " .. tostring(flag[2]), 16, 10 + (i-1)*14)
				love.graphics.setColor(255, 255, 255, 255)
			end
		end
		
		if debugMenuDir == 'mapmovement' then
			for i = 1, # debugMapMovement do
				local flag = debugMapMovement[i]
				if debugMenuCursor == i then
					debugtoolsDrawCursor() 
					love.graphics.setColor(0, 0, 0, 255)
				end
				love.graphics.print(flag, 16, 10 + (i-1)*14)
				love.graphics.setColor(255, 255, 255, 255)
			end
		end
		
		--- spawn directory
		if debugMenuDir == 'spawn' then
			for i = 1, # debugMenuSpawn do
				local flag = debugMenuSpawn[i]
				if debugMenuCursor == i then 
					debugtoolsDrawCursor() 
					love.graphics.setColor(0, 0, 0, 255)
				end
				love.graphics.print(flag, 16, 10 + (i-1)*14)
				love.graphics.setColor(255, 255, 255, 255)
			end
		end
		
		--- map gen directory
		if debugMenuDir == 'mapgen' then
			for i = 1, # debugMenuMapGen do
				local flag = debugMenuMapGen[i]
				if debugMenuCursor == i then 
					debugtoolsDrawCursor() 
					love.graphics.setColor(0, 0, 0, 255)
				end
				love.graphics.print(flag, 16, 10 + (i-1)*14)
				love.graphics.setColor(255, 255, 255, 255)
			end
		end
		
	end	
end

function debugtoolsDrawCursor()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle('fill', 14, 10 + (debugMenuCursor-1)*14, 320, 14)
end

--- Getters
function debugGetMenuOpen() return debugMenuOpen end