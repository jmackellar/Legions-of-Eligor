--- player.lua
--- The player object.  All information, data, and actions
--- related to the player.

local playerName = 'Jesse'
local playerLevel = 1
local playerExp = 0
local playerExpBase = 7
local playerClass = 'Vagrant'
local playerTurns = 0

local playerHealth = 100
local playerHealthMax = 100
local playerHealthRegen = 16
local playerHealthRegenTick = 1
local playerHealthRegenCount = 3

local playerMana = 100
local playerManaMax = 100
local playerManaRegen = 21
local playerManaRegenTick = 0
local playerManaRegenCount = 3

local playerSpellList = { }
local playerSpellPoints = 0

local playerX = 40
local playerY = 13

local playerVit = 5
local playerMent = 5
local playerEndur = 5
local playerWill = 5
local playerArmor = 0
local playerSpeed = 100

local playerViewRadius = 12
local playerFogCanCast = true

local playerPrev = 'spawn'

local playerAction = false
local playerActionLook = {1, 1}

local playerMenu = false
local playerMenuTablet = false

local playerGetDirection = false
local playerDirection = false
local playerCastingSpell = false

local playerModifiers = { }
local alphabet = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}

--- playerInit
--- Setups the player data.
function playerInit(name, level, health, mana, vit, ment, endur, will, class)
	playerName = name
	playerLevel = level
	playerClass = class
	playerHealth = health
	playerHealthMax = health
	playerMana = mana
	playerManaMax = mana
	playerVit = vit
	playerMent = ment
	playerEndur = endur
	playerWill = will
	--- Set up stats for class
	if gameClasses[playerClass] then	
		playerHealth = gameClasses[playerClass].health
		playerHealthMax = gameClasses[playerClass].health
		playerMana = gameClasses[playerClass].mana
		playerManaMax = gameClasses[playerClass].mana
		playerVit = gameClasses[playerClass].vit
		playerMent = gameClasses[playerClass].ment
		playerEndur = gameClasses[playerClass].endur
		playerWill = gameClasses[playerClass].will
		--- Set up correct levels of Health and Mana based on stats
		playerHealth = playerHPMax()
		playerMana = playerMPMax()
		--- Starting equipment and items
		itemStartingEquipmentClass(playerClass)
		itemStartingInventoryClass(playerClass)
	end
	--- Create player spell list
	if # playerSpellList == 0 then
		for i = 1, # gameClasses[playerClass].spells do
			table.insert(playerSpellList, {name = gameClasses[playerClass].spells[i].name, have = false})
		end
	end
	playerCastFog()
end

--- playerKeypressed
--- Key input that affects the player.
function playerKeypressed(key)
	--- if player is dead then dont allow any movement
	if playerHealth < 1 then return end
	--- if player has to give a direction don't allow any other inputs
	if playerGetDirection then
		local dx = 0
		local dy = 0
		if key == 'kp8' or key == 'k' then dx = 0 dy = -1 
		elseif key == 'kp9' or key == 'u' then dx = 1 dy = -1
		elseif key == 'kp6' or key == 'l' then dx = 1 dy = 0
		elseif key == 'kp3' or key == 'n' then dx = 1 dy = 1
		elseif key == 'kp2' or key == 'j' then dx = 0 dy = 1
		elseif key == 'kp1' or key == 'b' then dx = -1 dy = 1
		elseif key == 'kp4' or key == 'h' then dx = -1 dy = 0
		elseif key == 'kp7' or key == 'y' then dx = -1 dy = -1 end
		if dx ~= 0 or dy ~= 0 then
			playerDirection = {dx = dx, dy = dy}
			playerGetDirection = false
		end
		if not playerCastingSpell then
			return true
		end
	end
	
	--- normal game actions
	if not playerAction and not playerMenu and not itemGetInventoryOpen() then
		--- movement
		if key == 'kp8' or key == 'k' then playerMoveBy(0, -1) return true
		elseif key == 'kp9' or key == 'u' then playerMoveBy(1, -1) return true
		elseif key == 'kp6' or key == 'l' then playerMoveBy(1, 0) return true
		elseif key == 'kp3' or key == 'n' then playerMoveBy(1, 1) return true
		elseif key == 'kp2' or key == 'j' then playerMoveBy(0, 1) return true
		elseif key == 'kp1' or key == 'b' then playerMoveBy(-1, 1) return true
		elseif key == 'kp4' or key == 'h' then playerMoveBy(-1, 0) return true
		elseif key == 'kp7' or key == 'y' then playerMoveBy(-1, -1) return true 
		elseif key == 'kp5' or key == '.' and not (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) then gameFlipPlayerTurn() gameSetRedrawAll() return true end
		--- actions
		if key == 'o' then playerAction = 'openclose' messageRecieve("Open which door?") 
		elseif key == 'g' then itemPickup(playerX, playerY) return true 
		elseif key == 's' and (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) then gameSave() love.event.push('quit') return true
		elseif key == 'i' then itemInventorySetAction('look') itemInventoryOpenFlip() return true 
		elseif key == 'd' then itemInventorySetAction('drop') itemInventoryOpenFlip() return true 
		elseif key == 'e' then itemInventorySetAction('equip') itemInventoryOpenFlip() return true 
		elseif key == 'r' and not (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) then itemInventorySetAction('remove') itemInventoryOpenFlip() return true 
		elseif key == 'a' then itemInventorySetAction('apply') itemInventoryOpenFlip() return true 
		elseif key == 't' then itemInventorySetAction('throw') itemInventoryOpenFlip() return true
		elseif key == 'return' then playerUseTile()
		elseif key == 'z' and not (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) then messageRecieve("A-Z cast spell.  Any other key to cancel.") playerMenu = 'spell'
		elseif key == 'z' and (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) then playerMenu = 'spelllist' playerMenuSpellList = {view = 0, spell = false}
		elseif key == 'm' then playerMenu = 'messages' 
		elseif key == 'c' then playerMenu = 'character'

		elseif key == ';' then playerAction = 'look' playerActionLook = {playerX, playerY}
		
		elseif key == 'l' then playerMenu = 'stats' playerFreeStats = 5 
		
		elseif key == 'r' and (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) then playerAction = 'rest' messageRecieve("Resting... press any to stop resting.")
		elseif key == '/' and (love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')) then playerMenu = 'help' end	
		
		--- downstairs
		if (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) and key == '.' and mapGetTileName(playerX, playerY) == 'downstairs' then
			playerPrev = 'up'
			mapChangeFloor(1)
			messageRecieve("You descend down the stairs.")
			return true
		--- upstairs
		elseif (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) and key == ',' and mapGetTileName(playerX, playerY) == 'upstairs' then
			playerPrev = 'down'
			mapChangeFloor(-1)
			messageRecieve("You ascend up the stairs.")
			return true
		--- connections
		elseif (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) and key == '.' and mapGetTileName(playerX, playerY) == 'connection' then
			mapUseConnection(playerX, playerY) return true
		end
	elseif playerAction == 'openclose' then
		if key == 'kp8' or key == 'k' then playerUseDoor(playerX + 0, playerY + -1)
		elseif key == 'kp9' or key == 'u' then playerUseDoor(playerX + 1, playerY +  -1) return true
		elseif key == 'kp6' or key == 'l' then playerUseDoor(playerX + 1, playerY +  0) return true
		elseif key == 'kp3' or key == 'n' then playerUseDoor(playerX + 1, playerY + 1) return true
		elseif key == 'kp2' or key == 'j' then playerUseDoor(playerX + 0, playerY + 1) return true
		elseif key == 'kp1' or key == 'b' then playerUseDoor(playerX + -1, playerY + 1) return true
		elseif key == 'kp4' or key == 'h' then playerUseDoor(playerX + -1, playerY + 0) return true
		elseif key == 'kp7' or key == 'y' then playerUseDoor(playerX + -1, playerY + -1)return true end
	elseif playerAction == 'rest' then
		if key then
			playerAction = false
		end
	elseif playerAction == 'look' then
		local dx = 0
		local dy = 0
		consoleSetBorder(playerActionLook[1], playerActionLook[2] + 1, false)
		if key == 'kp8' or key == 'k' then dx = 0 dy = -1
		elseif key == 'kp9' or key == 'u' then dx = 1 dy = -1
		elseif key == 'kp6' or key == 'l' then dx = 1 dy = 0
		elseif key == 'kp3' or key == 'n' then dx = 1 dy = 1
		elseif key == 'kp2' or key == 'j' then dx = 0 dy = 1
		elseif key == 'kp1' or key == 'b' then dx = -1 dy = 1
		elseif key == 'kp4' or key == 'h' then dx = -1 dy = 0
		elseif key == 'kp7' or key == 'y' then dx = -1 dy = -1 end
		if playerActionLook[1] + dx > 1 and playerActionLook[1] + dx < mapGetWidth() then
			playerActionLook[1] = playerActionLook[1] + dx
		end
		if playerActionLook[2] + dy > 1 and playerActionLook[2] + dy < mapGetHeight() then
			playerActionLook[2] = playerActionLook[2] + dy
		end
		consoleSetBorder(playerActionLook[1], playerActionLook[2] + 1, true)
		if key == 'return' then 
			playerAction = false 
			consoleSetBorder(playerActionLook[1], playerActionLook[2] + 1, false)
		end
	elseif playerMenu == 'messages' then
		if key then playerMenu = false gameSetRedrawAll() end
	elseif playerMenu == 'help' then
		if key then playerMenu = false gameSetRedrawAll() end
	elseif playerMenu == 'spelllist' then
		if not playerMenuSpellList.spell then
			if key then
				for i = 1, # alphabet do
					if key == alphabet[i] then
						if gameClasses[playerClass].spells[i] then
							playerMenuSpellList.spell = gameClasses[playerClass].spells[i]
							return
						end
					end
				end
				if key == 'kp04' or key == 'h' then
					playerMenuSpellList.view = playerMenuSpellList.view - 4
				elseif key == 'kp06' or key == 'l' then
					playerMenuSpellList.view = playerMenuSpellList.view + 4
				else
					playerMenu = false
					gameSetRedrawAll()
				end
			end
		else
			if key then
				if key == 'l' then
					for k,v in ipairs(playerSpellList) do
						if v.name == playerMenuSpellList.spell.name and playerHaveSpellReq(playerMenuSpellList.spell) and playerHaveSpellLevel(playerMenuSpellList.spell) and playerSpellPoints > 0 then
							v.have = true
							playerSpellPoints = playerSpellPoints - 1
						end
					end
				else
					playerMenuSpellList.spell = false
				end
			end
		end
	elseif playerMenu == 'spell' then
		if key == 'return' or key == ' ' then
			playerMenu = false
			playerCastingSpell = false
			messageRecieve("Nevermind.")
			gameSetRedrawAll()
		end
		if playerCastingSpell then
			return playerCastSpell(playerCastingSpell)
		end
		if key then
			for i = 1, # alphabet do
				if key == alphabet[i] then
					return playerCastSpell(i)
				end
			end
		end
	elseif playerMenu == 'character' then
		if key then playerMenu = false end
		gameSetRedrawAll()
	elseif playerMenu == 'tablet' then
		if key then playerMenu = false end
		gameSetRedrawAll()
	elseif playerMenu == 'stats' then
		if not messageGetRestrictKeypress() then
			if key == '1' then
				playerVit = playerVit + 1
				playerFreeStats = playerFreeStats - 1
			elseif key == '2' then
				playerEndur = playerEndur + 1
				playerFreeStats = playerFreeStats - 1
			elseif key == '3' then
				playerMent = playerMent + 1
				playerFreeStats = playerFreeStats - 1
			elseif key == '4' then
				playerWill = playerWill + 1
				playerFreeStats = playerFreeStats - 1
			end
			if playerFreeStats < 1 then
				playerMenu = false
				playerFreeStats = 0
				gameSetRedrawAll()
			end
		end
	end
	if key == ' ' then
		return false
	end
	return false
end

--- playerUpdate
function playerUpdate(dt)
	if playerAction == 'rest' then
		gameFlipPlayerTurn()
		gameSetRedrawAll()
		--- If a creature is in vision of the player then 
		--- stop resting.
		if mapIsCreatureInVision(playerX, playerY) then
			playerAction = false
			messageRecieve("You stop resting.")
		--- If players health and mana are max then stop
		--- resting as well.
		elseif playerHealth == playerHPMax() and playerMana == playerMPMax() then
			playerAction = false
			messageRecieve("You've finished resting.")
		end
	end
end

--- playerSave
function playerSave()
	local p = "playersave.lua"
	local pf = love.filesystem.newFile(p)
	local t = {playerX = playerX, playerY = playerY, playerHealth = playerHealth, playerHealthMax = playerHealthMax, 
				playerMana = playerMana, playerManaMax = playerManaMax, playerVit = playerVit, playerMent = playerMent, 
				playerEnd = playerEndur, playerWill = playerWill, mapCurrentBranch = mapGetCurrentBranch(),
				mapCurrentFloor = mapGetCurrentFloor(), playerLevel = playerLevel, playerExp = playerExp,
				playerClass = playerClass, playerTurns = playerTurns, playerSpellList = playerSpellList,
				playerSpellPoints = playerSpellPoints}
	love.filesystem.write(p, Ser(t))
end

--- playerLoad
function playerLoad()
	local p = "playersave.lua"
	if love.filesystem.exists(p) then
		local c1 = love.filesystem.load(p)
		local t1 = c1()
		playerX = t1.playerX
		playerY = t1.playerY
		playerHealth = t1.playerHealth
		playerHealthMax = t1.playerHealthMax
		playerMana = t1.playerMana
		playerManaMax = t1.playerManaMax
		playerVit = t1.playerVit
		playerMent = t1.playerMent
		playerEndur = t1.playerEnd
		playerWill = t1.playerWill 
		playerLevel = t1.playerLevel
		playerExp = t1.playerExp
		playerClass = t1.playerClass
		playerTurns = t1.playerTurns
		playerSpellList = t1.playerSpellList
		playerSpellPoints = t1.playerSpellPoints
		mapSetCurrentBranch(t1.mapCurrentBranch)
		mapSetCurrentFloor(t1.mapCurrentFloor)
		return true
	end
	return false
end

--- playerCastSpell
--- Casts spell i
function playerCastSpell(i)
	--- i is the index of which key was pressed in the alphabet
	--- i corresponds not to the other order of spells in the data
	--- file, but to the order of spells that the player has learned,
	--- so we need to remap i to the correct data spell based on
	--- the players spell list.  If the player casted a spell that
	--- requires a direction then this step is not needed, so thus
	--- we skip it then.
	if not playerDirection then
		local name = false
		local ii = 0
		for k,v in ipairs(playerSpellList) do
			if v.have then
				ii = ii + 1
				if ii == i then
					name = v.name
					break
				end
			end
		end
		if not name then return end

		for j = 1, # gameClasses[playerClass].spells do
			if gameClasses[playerClass].spells[j].name == name then
				i = j
				break
			end
		end
	end

	--- Check if the spell exists and the player is able to cast it
	if gameClasses[playerClass].spells[i] then
		--- Now check mana cost.
		if gameClasses[playerClass].spells[i].mana <= playerMana then
			local spell = gameClasses[playerClass].spells[i]
			--- Does the spell require the player to input a direction to aim?
			if spell.direction and not playerCastingSpell then
				playerGetDirection = true
				playerCastingSpell = i
				messageRecieve("Cast " .. spell.name .. " in which direction?")
				gameSetRedrawAll()
				return
			end
			--- We either don't need a direction, or the player supplied a direction.
			--- Now actually cast the spell.
			if not spell.direction or playerDirection then
				--------------------------
				------- Vagrant
				if spell.name == 'Roll' then playerSpellRoll(spell) end
				if spell.name == 'Shoutout' then playerSpellShoutout(spell) end
				if spell.name == 'Spin Slice' then playerSpellSpinSlice(spell) end
				if spell.name == 'Double Strike' then playerSpellDoubleStrike(spell) end
				--------------------------
				------- Arcanist
				if spell.name == 'Arcane Dart' then playerSpellArcaneDart(spell) end
				if spell.name == 'Unstable Concoction' then playerSpellUnstableConcoction(spell) end
				if spell.name == 'Mystic Wind' then playerSpellMysticWind(spell) end
				if spell.name == 'Cyclone' then playerSpellCyclone(spell) end
				--------------------------
				--- Spell has been cast.  Turn off getting direction, 
				--- Subtract mana, close spell menu, and end player turn.
				playerGetDirection = false
				playerCastingSpell = false
				playerDirection = false
				playerMana = playerMana - spell.mana
				playerMenu = false
				return true
			end
		else
			messageRecieve("You don't have enough mana to cast that.")
			playerGetDirection = false
			playerCastingSpell = false
			playerDirection = false
			playerMenu = false
			gameSetRedrawAll()
			return false
		end
	end
	return false
end

--- playerSpellCyclone
--- A cyclone that lasts for a few turns and passively damages monsters
--- around the player.
function playerSpellCyclone(spell)
	local mod = {mod = 'cyclone', turn = spell.turn, val = spell.damage + playerScaling(spell.scaling), msgend = spell.msgend, range = spell.range}
	playerAddMod(mod)
	messageRecieve(spell.castmsg)
	gameFlipPlayerTurn()
	gameSetRedrawAll()
end

--- playerSpellMysticWind
--- Pushes a target enemy back a few spaces if nothing is behind it
function playerSpellMysticWind(spell)
	local sx = playerX
	local sy = playerY
	local dx = playerDirection.dx
	local dy = playerDirection.dy
	local dist = math.floor(spell.dist + playerScaling(spell.scaling))
	local msg = nil
	local pushback = 0
	local monster = nil

	--- Find a monster
	for range = 1, dist do
		sx = sx + dx
		sy = sy + dy
		pushback = dist - range
		if not mapGetWalkThru(sx, sy) then
			break
		end
		if not creatureIsTileFree(sx, sy) then
			monster = creatureGetCreatureAtTile(sx, sy)
			break
		end
	end

	--- If we found a monster then push it back!
	if monster then
		for i = 1, pushback do
			if mapGetWalkThru(monster.x + dx, monster.y + dy) and creatureIsTileFree(monster.x + dx, monster.y + dy) then
				monster.x = monster.x + dx
				monster.y = monster.y + dy 
				msg = monster.data.prefix .. ' ' .. monster.data.name .. ' is blown back!'
			else
				break
			end
		end
	end

	messageRecieve(spell.castmsg)
	if msg then messageRecieve(msg) end
	gameFlipPlayerTurn()
	gameSetRedrawAll()
end

--- playerSpellUnstableConcoction
--- Projectile that explodes on contact.  AoE damage
function playerSpellUnstableConcoction(spell)
	local sx = playerX
	local sy = playerY
	local ssX = playerX + playerDirection.dx
	local ssY = playerY + playerDirection.dy
	local r = 0
	local hits = { }
	
	--- Print message.
	messageRecieve(spell.castmsg)
	
	--- Shoot dart
	for range = 1, spell.dist do
		sx = sx + playerDirection.dx
		sy = sy + playerDirection.dy
		r = r + 1
		if not mapGetWalkThru(sx, sy) or not creatureIsTileFree(sx, sy) then
			for xx = sx - 1, sx + 1 do
				for yy = sy - 1, sy + 1 do
					table.insert(hits, {x = xx, y = yy})
				end
			end
			break
		end
	end	
	
	aeProjectile(ssX, ssY, playerDirection.dx, playerDirection.dy, r - 1, 'o', {100, 100, 255, 255})
	aeExplosion(sx, sy, 1, {100, 100, 255, 255})

	for k,v in pairs(hits) do
		creatureAttackedByPlayer(v.x, v.y, spell.damage + playerScaling(spell.scaling))
	end
	
	gameFlipPlayerTurn()
	gameSetRedrawAll()
end

--- playerSpellAranceDart
--- Straight projectile.
function playerSpellArcaneDart(spell)
	local sx = playerX
	local sy = playerY
	local ssX = playerX + playerDirection.dx
	local ssY = playerY + playerDirection.dy
	local r = 0
	
	--- Add the lastTurn flag if not set yet
	if not spell.lastTurn then
		spell.lastTurn = playerTurns
	end
	
	--- If dart was fired in the last few turns
	--- give the player some mana back.
	if spell.lastTurn ~= playerTurns then
		local t = playerTurns - spell.lastTurn
		if t <= spell.chaintime then
			local m = spell.chaintime - t + 1
			playerManaGain(m, m)
		end
	end
	
	--- Print message.
	messageRecieve(spell.castmsg)
	
	--- Shoot dart
	for range = 1, spell.dist do
		sx = sx + playerDirection.dx
		sy = sy + playerDirection.dy
		r = r + 1
		if not mapGetWalkThru(sx, sy) or not creatureIsTileFree(sx, sy) then
			aeProjectile(ssX, ssY, playerDirection.dx, playerDirection.dy, r - 1, 'o', {100, 100, 255, 255})
			creatureAttackedByPlayer(sx, sy, spell.damage + playerScaling(spell.scaling))
			break
		end
	end	
	
	gameFlipPlayerTurn()
	gameSetRedrawAll()
end

--- playerSpellDoubleStrike
--- Double strike.  Two melee attacks on one spot.
function playerSpellDoubleStrike(spell)
	local sx = playerX + playerDirection.dx
	local sy = playerY + playerDirection.dy
	messageRecieve(spell.castmsg)
	creatureAttackedByPlayer(sx, sy, playerCalcDamage())
	creatureAttackedByPlayer(sx, sy, playerCalcDamage())
	gameFlipPlayerTurn()
	playerCastFog()
	gameSetRedrawAll()
end

--- playerSpellSpinSlice
--- Spin Slice.  Hits all adjacent enemies to the player.
function playerSpellSpinSlice(spell)
	local sx = playerX
	local sy = playerY
	--- We want the message to be seen before
	--- any hit messages.  Immersion!!!
	messageRecieve(spell.castmsg)
	for xx = sx-1, sx+1 do
		for yy = sy-1, sy+1 do
			creatureAttackedByPlayer(xx, yy, playerCalcDamage())
		end
	end
	--- Graphics
	local tC = {175, 175, 175, 255}
	local bC = {0, 0, 0, 255}
	aePoint(sx, sy - 1, '|', tC, bC)
	aePoint(sx + 1, sy - 1, '/', tC, bC)
	aePoint(sx + 1, sy, '-', tC, bC)
	aePoint(sx + 1, sy + 1, '\\', tC, bC)
	aePoint(sx, sy + 1, '|', tC, bC)	
	aePoint(sx - 1, sy + 1, '/', tC, bC)
	aePoint(sx - 1, sy, '-', tC, bC)
	aePoint(sx - 1, sy - 1, '\\', tC, bC)
	aePoint(sx, sy - 1, '|', tC, bC)
	
	gameFlipPlayerTurn()
	playerCastFog()
	gameSetRedrawAll()
end

--- playerSpellRoll
--- Roll.  Player rolls forward in target direction. 
--- Stop before walls and creatures or stop when max distance is travelled.
function playerSpellRoll(spell)
	local sx = playerX
	local sy = playerY
	for i = 1, spell.dist do
		if mapGetWalkThru(sx + playerDirection.dx, sy + playerDirection.dy) and creatureIsTileFree(sx + playerDirection.dx, sy + playerDirection.dy) then
			sx = sx + playerDirection.dx
			sy = sy + playerDirection.dy
		else
			break
		end
	end
	
	--- Damage bonus
	local dam = 3 + playerScaling(spell.scaling)
	playerAddMod({mod = 'dam', val = dam, turn = 2, msgend = "You lower your weapon."})
	
	gameFlipPlayerTurn()
	messageRecieve(spell.castmsg)
	playerX = sx
	playerY = sy
	playerCastFog()
	gameSetRedrawAll()
end

--- playerSpellShoutout
--- Shoutout.  Player shouts loudly, reducing the armor
--- of nearby enemies centered around the player.
function playerSpellShoutout(spell)
	local sx = playerX
	local sy = playerY
	local armor = spell.armor + playerScaling(spell.scaling)
	for xx = math.max(1, sx - spell.dist), math.min(mapGetWidth(), sx + spell.dist) do
		for yy = math.max(1, sy - spell.dist), math.min(mapGetHeight(), sy + spell.dist) do
			creatureAddModAt({mod = 'armor', val = spell.armor, turn = spell.turns}, xx , yy)
		end
	end
	gameFlipPlayerTurn()
	messageRecieve(spell.castmsg)
	playerCastFog()
	gameSetRedrawAll()
end

--- playerUseDoor
--- opens or closes a target door.  If a door exists that is.
function playerUseDoor(x, y)
	if mapCheckTileAt(x, y, 'closeddoor') then
		mapSwitchDoor(x, y)
	elseif mapCheckTileAt(x, y, 'opendoor') then
		mapSwitchDoor(x, y)
	else
		messageRecieve("There is no door there!")
	end
	playerAction = false
end

--- playerGetMod
--- Searches through modifiers to find a passed mod and return
--- the adjusted value.
function playerGetMod(mod)
	local val = 0
	for i = 1, # playerModifiers do
		if playerModifiers[i].mod == mod then
			val = val + playerModifiers[i].val
		end
	end
	return val
end

--- playerAddMod
--- Adds a passed modifier to the player.  Does not add the mod if
--- another mod of the same type already exists, unless an exception
--- to that rule is passed.
function playerAddMod(modifier, exception)
	local exc = exception or false
	local found = false
	--- Search existing modifiers to determine if the player
	--- already has the mod type or not.
	for i = 1, # playerModifiers do
		if playerModifiers[i].mod == modifier.mod then
			found = true
			break
		end
	end
	--- If the mod type doesn't already exist or if the
	--- exception was passed then add the mod to the player.
	if not found or exc then
		local mod = {}
		for k,v in pairs(modifier) do
			mod[k] = v
		end
		table.insert(playerModifiers, mod)
	end
end

--- playerModifierUpdate
--- Ticks down all modifiers per turn and plays modifiers than are used on a per turn basis like cyclone.
function playerModifierUpdate()
	for i = # playerModifiers, 1, -1 do
		playerModifierUseTurn(playerModifiers[i])
		playerModifiers[i].turn = playerModifiers[i].turn - 1
		if playerModifiers[i].turn <= 0 then
			messageRecieve(playerModifiers[i].msgend)
			table.remove(playerModifiers, i)
		end
	end
end

--- playerModifierUseTurn
--- Logic for modifiers that perform actions every turn
function playerModifierUseTurn(mod)
	if mod.mod == 'cyclone' then
		playerModAOEDamage(mod.range, mod.val)
	end
end

--- playerModAOEDamage
--- Deals damage in a range around the player.
function playerModAOEDamage(range, dam)
	for x = playerX - range, playerX + range do
		for y = playerY - range, playerY + range do
			if x >= 1 and y >= 1 and x <= mapGetWidth() and y <= mapGetHeight() then
				creatureAttackedByPlayer(x, y, dam)
			end
		end
	end
end

--- playerRegenTurn
--- ticks players health and mana regen rates.
function playerRegenTurn()
	playerManaRegenTick = playerManaRegenTick - 1
	playerHealthRegenTick = playerHealthRegenTick - 1
	if playerManaRegenTick <= 0 then
		playerManaRegenTick = playerManaRegen
		playerMana = playerMana + math.ceil(playerGetWill() / 2)
		if playerMana > playerMPMax() then
			playerMana = playerMPMax()
		end
	end
	if playerHealthRegenTick <= 0 then
		playerHealthRegenTick = playerHealthRegen
		playerHealth = playerHealth + math.ceil(playerGetEndur() / 2)
		if playerHealth > playerHPMax() then
			playerHealth = playerHPMax()
		end
	end
end

--- playerCastFog
--- Calculates fog from player position and radius.
function playerCastFog()
	if not playerFogCanCast then return end
	mapCalcFog(playerX, playerY, playerViewRadius)
	gameSetRedrawPlayer()
	gameSetRedrawCreature()
	gameSetRedrawItem()
end

--- playerMovBy
--- moves the player by the specified amount.
function playerMoveBy(dx, dy)
	local oldX = playerX
	local oldY = playerY
	local newX = playerX + dx
	local newY = playerY + dy
	if mapGetWalkThru(newX, newY) then
		if creatureIsTileFree(newX, newY) then
			playerX = newX
			playerY = newY
			mapDrawTile(oldX, oldY)
			playerCastFog()
			gameFlipPlayerTurn()
			itemDidPlayerWalkOverItem(newX, newY)
			mapDidPlayerWalkOverObject(newX, newY)
		else
			creatureAttackedByPlayer(newX, newY, playerCalcDamage())
			playerCastFog()
			gameFlipPlayerTurn()
		end
	end
end

--- playerHeal
--- heals a player between passed minimum and maximum values.
function playerHeal(m1, m2)
	playerHealth = playerHealth + math.random(m1, m2)
	playerHealth = math.min(playerHealth, playerHPMax())
end

--- playerManaGain
--- heals player mana between passed minimum and maximum values.
function playerManaGain(m1, m2)
	playerMana = playerMana + math.random(m1, m2)
	playerMana = math.min(playerMana, playerMPMax())
end

--- playerAttackedByCreature
--- player gets attacked by a creature.  
function playerAttackedByCreature(name, prefix, dam)	
	--- calculate damage reduction from armor
	local arm = playerArmor + itemGetEquipmentArmor()
	local damred = 0
	for i = 1, arm do
		if i < (arm * 0.5) then
			damred = damred + 1
		else
			damred = damred + math.random(0, 1)
		end
	end
	
	--- Hit player with the damage now.
	playerRecieveDamage(dam - damred)
	
	--- different messages for hitting and dodging.
	messageRecieve("You were hit by " .. prefix .. name .. ".")
end

--- playerRecieveDamage
--- Takes passed damage value and subtracts it from player health.
function playerRecieveDamage(dam)
	playerHealth = playerHealth - math.max(0, dam)
	--- did the player die?  if so game fucking over.
	if playerHealth < 1 then
		messageRecieve("You have died...")
		messageRecieve("Game Over")
		gameClearSave()
		mainDisableSaves()
	end
end

--- playerMoveTo
--- moves player to coordinates.  Doesn't check for collision.  Don't cast fog.
function playerMoveTo(x, y)
	local oldX = playerX
	local oldY = playerY
	playerX = x
	playerY = y
end

--- playerHaveSpell
--- Returns if true or false if a player has learned the passed spell by name
function playerHaveSpell(name)
	for k,v in ipairs(playerSpellList) do
		if v.name == name then
			return v.have
		end
	end
	return false 
end

--- 
--- Draws the player menu if it is open.
function playerDrawMenu()
	if playerMenu then
		--- Messages
		--- Displays all recent messages that the player received.
		if playerMenu == 'messages' then
			local msg = messageGetMessages()
			consoleFlush()
			for i = 1, # msg do
				consolePrint({string = msg[i], x = 1, y = i})
			end

		--- Spell List
		--- Lists all spells and allows the player to view spells or learn them
		elseif playerMenu == 'spelllist' then
			consoleFlush()

			local maxLevel = 0
			local spell = false
			local alpha = 0

			--- Spell points
			local w = 15
			if playerSpellPoints == 1 then
				consolePrint({string = '1 Spell Point', x = 3, y = 3, textColor = {255, 157, 0, 255}})
				w = 14
			elseif playerSpellPoints > 1 then
				consolePrint({string = playerSpellPoints .. ' Spell Points', x = 3, y = 3, textColor = {255, 157, 0, 255}})
				w = 15
				if playerSpellPoints > 9 then
					w = 16
				end
			end
			if playerSpellPoints > 0 then
				local color = {181, 112, 0, 255}
				consoleDrawLine({char = '─', x1 = 2, y1 = 2, x2 = 2 + w, y2 = 2, textColor = color})
				consoleDrawLine({char = '─', x1 = 2, y1 = 4, x2 = 2 + w, y2 = 4, textColor = color})
				consolePut({char = '│', x = 2, y = 3, textColor = color})
				consolePut({char = '│', x = 2 + w, y = 3, textColor = color})
				consolePut({char = '┌', x = 2, y = 2, textColor = color})
				consolePut({char = '└', x = 2, y = 4, textColor = color})
				consolePut({char = '┐', x = 2 + w, y = 2, textColor = color})
				consolePut({char = '┘', x = 2 + w, y = 4, textColor = color})
			end

			for i = 1, # gameClasses[playerClass].spells do
				local spell = gameClasses[playerClass].spells[i]
				if spell.level > maxLevel then 
					maxLevel = spell.level
				end
			end

			if playerMenuSpellList.view > math.floor(8 + ((maxLevel - 2) * 25)) then
				playerMenuSpellList.view = math.floor(8 + ((maxLevel - 2) * 25))
			end
			if playerMenuSpellList.view < 0 then
				playerMenuSpellList.view = 0
			end

			for k,v in ipairs(playerSpellList) do
				alpha = alpha + 1
				--- Find which spell we are looking at
				for i = 1, # gameClasses[playerClass].spells do
					if gameClasses[playerClass].spells[i].name == v.name then
						spell = gameClasses[playerClass].spells[i]
						break
					end
				end
				--- Draw the spell box
				local color = {150, 150, 150, 255}
				local x = 8 + ((spell.level - 1) * 25) - playerMenuSpellList.view 
				local y = spell.y * 6
				if playerHaveSpell(spell.name) then
					color = {255, 238, 0, 255}
				end
				for xx = x, x + 2 + math.max(string.len(spell.name)+2, string.len("   Level:" .. spell.level)) do
					consolePut({char = '─', x = xx, y = y, textColor = color})
					consolePut({char = '─', x = xx, y = y+3, textColor = color})
				end
				for yy = y, y + 3 do
					consolePut({char = '│', x = x, y = yy, textColor = color})
					consolePut({char = '│', x = x + 2 + math.max(string.len(spell.name)+2, string.len("   Level:" .. spell.level)), y = yy, textColor = color})
				end
				consolePut({char = '┌', x = x, y = y, textColor = color})
				consolePut({char = '└', x = x, y = y+3, textColor = color})
				consolePut({char = '┐', x = x + 2 + math.max(string.len(spell.name)+2, string.len("   Level:" .. spell.level)), y = y, textColor = color})
				consolePut({char = '┘', x = x + 2 + math.max(string.len(spell.name)+2, string.len("   Level:" .. spell.level)), y = y+3, textColor = color})
				--- Spell Name and Letter
				consolePrint({string = '[' .. string.upper(alphabet[alpha]) .. ']', x = x + 1, y = y + 1, textColor = {255, 157, 0, 255}})
				consolePrint({string = spell.name, x = x + 4, y = y + 1})
				--- Level requirement
				local lColor = {255, 75, 75, 255}
				if playerLevel >= spell.level then
					lColor = {75, 255, 75, 255}
				end
				consolePrint({string = 'Level:' .. spell.level, x = x + 4, y = y + 2, textColor = lColor})
				--- Requirements
				if spell.req then
					--- Find the required spell
					local req = spell.req
					for i = 1, # gameClasses[playerClass].spells do
						if gameClasses[playerClass].spells[i].name == req then
							req = gameClasses[playerClass].spells[i]
							break
						end
					end
					--- Find start cooridnates, end coordinates, and slope
					local x = 8 + ((req.level - 1) * 25) - playerMenuSpellList.view 
						  x = x + 2 + math.max(string.len(req.name)+2, string.len("   Level:" .. req.level)) + 1
					local y = req.y * 6 + spell.y
					local ex = 8 + ((spell.level - 1) * 25) - playerMenuSpellList.view - 1
					local ey = spell.y * 6 + 1
					if req.y == spell.y then
						y = req.y * 6 + 1
					end
					consoleDrawLine({char = '*', x1 = x, y1 = y, x2 = ex, y2 = ey, textColor = color})
				end
			end

			--- Directions
			consolePrint({string = 'Movement keys to scroll', x = 56, y = 1})
			consolePrint({string = 'A-Z examine spell', x = 56, y = 2})
			consolePrint({string = 'Any other key to close', x = 56, y = 3})

			--- Scroll Bar
			consoleDrawLine({char = '═', x1 = 1, y1 = consoleGetWindowHeight(), x2 = consoleGetWindowWidth(), y2 = consoleGetWindowHeight()})
			consolePut({char = '<', x = 1, y = consoleGetWindowHeight(), border = true})
			consolePut({char = '>', x = consoleGetWindowWidth(), y = consoleGetWindowHeight(), border = true})
			local max = math.floor(8 + ((maxLevel - 2) * 25))
			local sw = math.ceil(78 * (max / 78))
			local sx = math.max(math.ceil( (78 - sw) * (playerMenuSpellList.view / max) ) + 1, 2)
			consoleDrawLine({char = '▒', x1 = sx, y1 = consoleGetWindowHeight(), x2 = sx + sw, y2 = consoleGetWindowHeight(), textColor = {200, 200, 200, 255}, backColor = {200, 200, 200, 255}})

			--- Spell Look
			if playerMenuSpellList.spell then
				local sx = 20
				local sy = 4
				local w = 40
				local h = 19
				local spell = playerMenuSpellList.spell
				local color = {150, 150, 150, 255}
				if playerHaveSpell(spell.name) then
					color = {255, 238, 0, 255}
				end
				for x = sx, sx + w do
					for y = sy, sy + h do
						consolePut({char = '', x = x, y = y})
						if x < sx + 1 or x > sx + w - 1 then
							consolePut({char = '│', x = x, y = y, textColor = color})
						end
						if y < sy + 1 or y > sy + h - 1 then
							consolePut({char = '─', x = x, y = y, textColor = color})
						end
					end
				end
				consolePut({char = '┌', x = sx, y = sy, textColor = color})
				consolePut({char = '└', x = sx, y = sy + h, textColor = color})
				consolePut({char = '┐', x = sx + w, y = sy, textColor = color})
				consolePut({char = '┘', x = sx + w, y = sy + h, textColor = color})

				--- Spell Name
				consolePrint({string = spell.name, x = sx + 2, y = sy + 1})
				consolePrint({string = 'Level:', x = sx  + w - 2 - string.len('Level:' .. spell.level), y = sy + 1, textColor = {237, 222, 161, 255}})
				consolePrint({string = spell.level, x = sx + w - 2 - string.len(spell.level), y = sy + 1})

				--- Mana Cost
				consolePrint({string = 'Mana:', x = sx + w - 10 - string.len('level:' .. spell.level), y = sy + 1, textColor = {75, 75, 255, 255}})
				consolePrint({string = spell.mana, x = sx + w - 5 - string.len('level:' .. spell.level), y = sy + 1})

				--- Spell Description
				for i = 1, # spell.desc do
					consolePrint({string = spell.desc[i], x = sx + 2, y = sy + 2 + i})
				end

				--- Scaling
				if spell.scaling then
					consolePrint({string = 'Spell Scaling', x = sx + 2, y = sy + 10})
					consolePrint({string = spell.scaledesc, x = sx + 2, y = sy + 11})
					local i = 0
					for k,v in pairs(spell.scaling) do
						i = i + 1
						if k == 'vit' then stat = 'Vitality' color = {224, 119, 119, 255} end
						if k == 'endur' then stat = 'Endurance' color = {119, 224, 119, 255} end
						if k == 'ment' then stat = 'Mentality' color = {119, 119, 224, 255} end
						if k == 'will' then stat = 'Willpower' color = {213, 115, 240, 255} end
						consolePrint({string = stat, x = sx + 4, y = sy + 12 + i, textColor = color})
						consolePrint({string = v * 100 .. '%', x = sx + 5 + string.len(stat), y = sy + 12 + i})
					end
				else
					consolePrint({string = "No Scaling", x = sx + 2, y = sy + 10})
				end

				--- Directions
				consolePrint({string = '[L] Learn Spell', x = sx + 2, y = sy + h - 1})
				consolePrint({string = 'Any Key to Close', x = sx + w - 2 - 15, y = sy + h - 1})

			end

		--- Tabler
		--- Display tablet message
		elseif playerMenu == 'tablet' then
			consoleFlush()

			--- Borders
			local w = consoleGetWindowWidth()
			local h = consoleGetWindowHeight()	
			local bC = {199, 136, 93, 255}
			local tC = {89, 60, 41, 255}
			for x = 1, w do
				consolePut({char = '─', x = x, y = 1, backColor = bC, textColor = tC})
				consolePut({char = '─', x = x, y = h, backColor = bC, textColor = tC})
			end
			for y = 1, h do
				consolePut({char = '│', x = 1, y = y, backColor = bC, textColor = tC})
				consolePut({char = '│', x = w, y = y, backColor = bC, textColor = tC})
			end
			consolePut({char = '┌', x = 1, y = 1, backColor = bC, textColor = tC})
			consolePut({char = '└', x = 1, y = h, backColor = bC, textColor = tC})
			consolePut({char = '┐', x = w, y = 1, backColor = bC, textColor = tC})
			consolePut({char = '┘', x = w, y = h, backColor = bC, textColor = tC})

			--- Message
			local startX, startY = playerTabletCenter()
			for i = 1, # playerMenuTablet do
				consolePrint({string = playerMenuTablet[i], x = startX, y = startY + i})
			end

			--- Quit help
			consolePrint({string = 'Press any key to return', x = 3, y = 25})
			
		--- Stats
		--- Upgrade player stats
		elseif playerMenu == 'stats' then
		
			if not messageGetRestrictKeypress() then
			
				local startx = 17
				local starty = 5
				local width = 45
				local height = 13
				
				--- Window
				for x = startx, startx + width do
					for y = starty, starty + height do
						consolePut({char = ' ', x = x, y = y})
						if x == 1 or x == startx + width then
							consolePut({char = '│', x = startx, y = y, textColor = {237, 222, 161, 255}})
							consolePut({char = '│', x = startx + width, y = y, textColor = {237, 222, 161, 255}})
						end
						if y == 1 or y == starty + height then
							consolePut({char = '─', x = x, y = starty, textColor = {237, 222, 161, 255}})
							consolePut({char = '─', x = x, y = starty + height, textColor = {237, 222, 161, 255}})
						end
					end
				end
				consolePut({char = '┌', x = startx, y = starty, textColor = {237, 222, 161, 255}})
				consolePut({char = '┐', x = startx + width, y = starty, textColor = {237, 222, 161, 255}})
				consolePut({char = '└', x = startx, y = starty + height, textColor = {237, 222, 161, 255}})
				consolePut({char = '┘', x = startx + width, y = starty + height, textColor = {237, 222, 161, 255}})
				
				--- Instructions
				consolePrint({string = 'Level Up', x = startx + math.floor(width/2) - 3, y = starty, textColor = {237, 222, 161, 255}})
				consolePrint({string = 'Choose an attribute to increase.', x = startx + 2, y = starty + 2})
				consolePrint({string = 'Points:', x = startx + 2 + 33, y = starty + 2, textColor = {234, 255, 0, 255}})
				consolePrint({string = playerFreeStats, x = startx + 2 + 33 + 8, y = starty + 2})
				
				--- Stats
				
				consolePrint({string = '[1]', x = startx + 7, y = starty + 4, textColor = {234, 255, 0, 255}})
				consolePrint({string = 'Vitality', x = startx + 11, y = starty + 4, textColor = {224, 119, 119, 255}})
				consolePrint({string = playerVit, x = startx + 14, y = starty + 6})
				
				consolePrint({string = '[2]', x = startx + 26, y = starty + 4, textColor = {234, 255, 0, 255}})
				consolePrint({string = 'Endurance', x = startx + 30, y = starty + 4, textColor = {119, 224, 119, 255}})
				consolePrint({string = playerEndur, x = startx + 33, y = starty + 6})
				
				consolePrint({string = '[3]', x = startx + 7, y = starty + 9, textColor = {234, 255, 0, 255}})
				consolePrint({string = 'Mentality', x = startx + 11, y = starty + 9, textColor = {119, 119, 224, 255}})
				consolePrint({string = playerMent, x = startx + 14, y = starty + 11})
				
				consolePrint({string = '[4]', x = startx + 26, y = starty + 9, textColor = {234, 255, 0, 255}})
				consolePrint({string = 'Willpower', x = startx + 30, y = starty + 9, textColor = {213, 115, 240, 255}})
				consolePrint({string = playerWill, x = startx + 33, y = starty + 11})
				
			end	
			
		--- Character
		--- Character stats and attributes
		elseif playerMenu == 'character' then
			consoleFlush()
			
			--- Border
			for x = 1, consoleGetWindowWidth() do
				consolePut({char = '─', x = x, y = 1, textColor = {237, 222, 161, 255}})
				consolePut({char = '─', x = x, y = consoleGetWindowHeight(), textColor = {237, 222, 161, 255}})
			end
			for y = 1, consoleGetWindowHeight() do
				consolePut({char = '│', x = 1, y = y, textColor = {237, 222, 161, 255}})
				consolePut({char = '│', x = consoleGetWindowWidth(), y = y, textColor = {237, 222, 161, 255}})
			end
			consolePut({char = '┌', x = 1, y = 1, textColor = {237, 222, 161, 255}})
			consolePut({char = '┐', x = consoleGetWindowWidth(), y = 1, textColor = {237, 222, 161, 255}})
			consolePut({char = '└', x = 1, y = consoleGetWindowHeight(), textColor = {237, 222, 161, 255}})
			consolePut({char = '┘', x = consoleGetWindowWidth(), y = consoleGetWindowHeight(), textColor = {237, 222, 161, 255}})
		
			--- Name, Class, Level
			consolePrint({string = gameClasses[playerClass].pername, x = 3, y = 3})
			consolePrint({string = playerClass, x = 3, y = 4, textColor = {237, 222, 161, 255}})
			consolePrint({string = "Level:", x = 3, y = 5, textColor = {237, 222, 161, 255}})
			consolePrint({string = playerLevel, x = 10, y = 5})
			
			--- Health
			consolePrint({string = 'Health:', x = 3, y = 8, textColor = {255, 0, 0, 255}})
			consolePrint({string = playerHealth .. "/" .. playerHPMax(), x = 11, y = 8})
			
			--- Mana
			consolePrint({string = 'Mana:', x = 3, y = 9, textColor = {75, 75, 255, 255}})
			consolePrint({string = playerMana .. "/" .. playerMPMax(), x = 11, y = 9})
			
			--- Armor 
			consolePrint({string = 'Armor:', x = 3, y = 12, textColor = {234, 255, 0, 255}})
			consolePrint({string = playerArmor + itemGetEquipmentArmor(), x = 10, y = 12})
			
			--- Damage Reduction
			consolePrint({string = 'Damage Reduction', x = 3, y = 14, textColor = {234, 255, 0, 255}})
			local arm = playerArmor + itemGetEquipmentArmor()
			local drmin = 0
			local drmax = 0
			for i = 1, arm do
				if i < (arm * 0.55) then
					drmin = drmin + 1
				end
				drmax = drmax + 1
			end
			consolePrint({string = '(' .. 	drmin .. '-' .. drmax ..')', x = 5, y = 15})
	
			--- Attack Damage
			consolePrint({string = 'Attack Damage', x = 3, y = 16, textColor = {234, 255, 0, 255}})
			local dammin, dammax = itemGetEquipmentDamageRange()
			if dammax == 0 then
				dammin = 1
				dammax = 3
			end
			consolePrint({string = '(' .. dammin .. '-' .. dammax .. ')', x = 5, y = 17})
			
			--- Location, Floor
			consolePrint({string = 'Location:', x = 28, y = 3, textColor = {222, 207, 120, 255}})
			consolePrint({string = mapGetCurrentBranch(), x = 38, y = 3})
			consolePrint({string = 'Floor:', x = 39 + string.len(mapGetCurrentBranch()), y = 3, textColor = {222, 207, 120, 255}})
			consolePrint({string = mapGetCurrentFloor(), x = 46 + string.len(mapGetCurrentBranch()), y = 3})
			
			--- Experience
			consolePrint({string = 'Experience:', x = 28, y = 4, textColor = {222, 207, 120, 255}})
			consolePrint({string = playerExp .. "/" .. (((playerLevel)^2) * playerExpBase), x = 40, y = 4})
			
			--- Stats
			consolePrint({string = 'Vitality:', x = 28, y = 8, textColor = {224, 119, 119, 255}})
			consolePrint({string = playerGetVit() .. "(" .. playerVit .. "+" .. (playerGetVit() - playerVit) .. ")", x = 39, y = 8})
			consolePrint({string = 'Endurace:', x = 28, y = 10, textColor = {119, 224, 119, 255}})
			consolePrint({string = playerGetEndur() .. "(" .. playerEndur .. "+" .. (playerGetEndur() - playerEndur) .. ")", x = 39, y = 10})
			consolePrint({string = 'Mentality:', x = 28, y = 12, textColor = {119, 119, 224, 255}})
			consolePrint({string = playerGetMent() .. "(" .. playerMent .. "+" .. (playerGetMent() - playerMent) .. ")", x = 39, y = 12})
			consolePrint({string = 'Willpower:', x = 28, y = 14, textColor = {213, 115, 240, 255}})
			consolePrint({string = playerGetWill() .. "(" .. playerWill .. "+" .. (playerGetWill() - playerWill) .. ")", x = 39, y = 14})
		
		--- Help
		--- Displays all game commands.
		elseif playerMenu == 'help' then
			consoleFlush()
			--- Movement help
			consolePrint({string = 'Movement', x = 6, y = 1})
			consolePrint({string = "7 8 9", x = 2, y = 3})
			consolePrint({string = " \\^/ ", x = 2, y = 4})
			consolePrint({string = "4<5>6", x = 2, y = 5})
			consolePrint({string = " /v\\ ", x = 2, y = 6})
			consolePrint({string = "1 2 3", x = 2, y = 7})
			consolePrint({string = "1-4, 6-9 Move", x = 9, y = 3})
			consolePrint({string = "5 Skip Turn", x = 9, y = 4})
			--- Command help
			consolePrint({string = "Actions", x = 6, y = 10})
			consolePrint({string = "i - View Inventory", x = 2, y = 12})
			consolePrint({string = "e - Equip Item", x = 2, y = 13})
			consolePrint({string = "r - Remove Equipment", x = 2, y = 14})
			consolePrint({string = "a - Apply Item", x = 2, y = 15})
			consolePrint({string = "t - Throw Item", x = 2, y = 16})
			consolePrint({string = "g - Pick Up Item", x = 2, y = 17})
			consolePrint({string = "d - Drop Item", x = 2, y = 18})
			consolePrint({string = "o - Use Door", x = 2, y = 19})
			consolePrint({string = "z - Cast Spell", x = 2, y = 20})
			consolePrint({string = 'Enter/Return - Use Map Tile', x = 30, y = 4})
			consolePrint({string = "R - Rest", x = 30, y = 12})
			consolePrint({string = '; - Look', x = 30, y = 13})
			consolePrint({string = "c - Character Sheet", x = 30, y = 3})
		
			consolePrint({string = "m - View Recent Messages", x = 2, y = 23})			
			consolePrint({string = "? - This Help Screen", x = 2, y = 24})
		elseif playerMenu == 'spell' and not playerCastingSpell then
			
			local sx = 1
			local sy = 2
			local w = 35
			local h = 0
			local count = 0

			--- Determine how many spells we have
			for k,v in ipairs(playerSpellList) do
				if v.have then
					count = count + 1
				end
			end
			h = count + 1

			--- Print spell list
			for x = sx, sx + w do
				for y = sy, sy + h do
					consolePut({char = '', x = x, y = y})
					if x < sx + 1 or x > sx + w - 1 then
						consolePut({char = '│', x = x, y = y, textColor = {237, 222, 161, 255}})
					end
					if y < sy + 1 or y > sy + h - 1 then
						consolePut({char = '─', x = x, y = y, textColor = {237, 222, 161, 255}})
					end
				end
			end
			consolePut({char = '┌', x = sx, y = sy, textColor = {237, 222, 161, 255}})
			consolePut({char = '└', x = sx, y = sy + h, textColor = {237, 222, 161, 255}})
			consolePut({char = '┐', x = sx + w, y = sy, textColor = {237, 222, 161, 255}})
			consolePut({char = '┘', x = sx + w, y = sy + h, textColor = {237, 222, 161, 255}})

			--- Print spells now
			local i = 0
			for k,v in ipairs(playerSpellList) do
				if v.have then
					i = i + 1
					consolePrint({string = '[' .. string.upper(alphabet[i]) .. ']', x = sx + 1, y = sy + i, textColor = {237, 222, 161, 255}})
					consolePrint({string = v.name, x = sx + 5, y = sy + i})
					--- Get spell mana cost
					local mana = false
					for j = 1, # gameClasses[playerClass].spells do
						if gameClasses[playerClass].spells[j].name == v.name then
							mana = gameClasses[playerClass].spells[j].mana
						end
					end
					if mana then
						consolePrint({string = mana, x = sx + w - string.len(mana), y = sy + i, textColor = {75, 75, 255, 255}})
					end
				end
			end

		end
	end

	--- Player look at
	--- Lets do it in this fucntion just to make things simple
	if playerAction == 'look' then
		local tile, tileSeen, creature, item = playerLookAt()
		consolePrint({string = '                                                                                ', x = 1, y = 1})
		if tileSeen then
			consolePut({char = tile.char, x = 1, y = 1, textColor = tile.textColor, backColor = tile.backColor})
			consolePut({char = '-', x = 3, y = 1})
			consolePrint({string = tile.name, x = 5, y = 1})
			if creature then
				consolePut({char = creature.data.char, x = 25, y = 1, textColor = creature.data.textColor, backColor = creature.data.backColor})
				consolePut({char = '-', x = 27, y = 1})
				consolePrint({string = creature.data.name, x = 29, y = 1})
			end
			--[[if item then
				consolePut({char = item.char, x = 50, y = 1, textColor = item.textColor, backColor = item.backColor})
				consolePut({char = '-', x = 52, y = 1})
				consolePrint({string = item.name, x = 54, y = 1})
			end]]--			--- I decided I didn't want to see items this way.
		end
	end
end

--- playerDrawHud
--- draw the player hud with health, mana, stats, and other information.
function playerDrawHud()
	local startY = consoleGetWindowHeight() - 2
	consoleFlushRow(startY)
	consoleFlushRow(startY + 1)
	--- HUD border
	--consolePrint({string = "----------------------------------------------------------------------------------", x = 1, y = startY - 1})
	--consolePrint({string = "----------------------------------------------------------------------------------", x = 1, y = startY + 2})
	for x = 1, 82 do
		consolePut({char = '─', x = x, y = startY - 1})
		consolePut({char = '─', x = x, y = startY + 2})
	end
	--- Hud
	consolePut({char = '│', x = 1, y = startY})
	consolePut({char = '│', x = 1, y = startY+1})
	consolePut({char = '┌', x = 1, y = startY-1})
	consolePut({char = '└', x = 1, y = startY+2})
	consolePrint({string = playerClass .. " Level " .. playerLevel, x = 4, y = startY, textColor = {222, 207, 120, 255}})
	--consolePrint({string = "Experience:", x = 4, y = startY+1, textColor = {222, 207, 120, 255}})
	--consolePrint({string = playerExp .. "/" .. (((playerLevel)^2) * playerExpBase), x = 15, y = startY+1})
	--- XP Bar
	local perc = playerExp / (((playerLevel)^2) * playerExpBase)
	local pips = math.floor(14 * perc)
	consolePrint({string = "[--------------]", x = 4, y = startY + 1})
	consolePrint({string = "EXP", x = 11, y = startY + 1})
	for x = 5, 5 + pips do
		consolePut({char = '', x = x, y = startY + 1, backColor = {255, 102, 0, 255}})
		if x == 11 then
			consolePut({char = 'E', x = x, y = startY + 1, backColor = {255, 102, 0, 255}})
		elseif x == 12 then
			consolePut({char = 'X', x = x, y = startY + 1, backColor = {255, 102, 0, 255}})
		elseif x == 13 then
			consolePut({char = 'P', x = x, y = startY + 1, backColor = {255, 102, 0, 255}})
		end	
	end
	consolePut({char = '│', x = 22, y = startY})
	consolePut({char = '│', x = 22, y = startY+1})
	consolePut({char = '┬', x = 22, y = startY-1})
	consolePut({char = '┴', x = 22, y = startY+2})

	consolePrint({string = "HP:", x = 25, y = startY, textColor = {255, 0, 0, 255}})
	consolePrint({string = playerHealth .. "/" .. playerHPMax(), x = 28, y = startY})
	consolePrint({string = "MP:", x = 25, y = startY + 1, textColor = {75, 75, 255, 255}})
	consolePrint({string = playerMana .. "/" .. playerMPMax(), x = 28, y = startY + 1})
	consolePrint({string = 'AC:', x = 36, y = startY, textColor = {234, 255, 0, 255}})
	consolePrint({string = playerArmor + itemGetEquipmentArmor(), x = 39, y = startY})
	consolePut({char = '│', x = 43, y = startY})
	consolePut({char = '│', x = 43, y = startY+1})
	consolePut({char = '┬', x = 43, y = startY-1})
	consolePut({char = '┴', x = 43, y = startY+2})
	
	
	consolePrint({string = "Vit:", x = 46, y = startY, textColor = {224, 119, 119, 255}})
	consolePrint({string = playerGetVit(), x = 50, y = startY})
	consolePrint({string = "Mnt:", x = 46, y = startY+1, textColor = {119, 119, 224, 255}})
	consolePrint({string = playerGetMent(), x = 50, y = startY+1})
	consolePrint({string = "End:", x = 53, y = startY, textColor = {119, 224, 119, 255}})
	consolePrint({string = playerGetEndur(), x = 57, y = startY})
	consolePrint({string = "Wil:", x = 53, y = startY+1, textColor = {213, 115, 240, 255}})
	consolePrint({string = playerGetWill(), x = 57, y = startY+1})	
	consolePut({char = '│', x = 61, y = startY})
	consolePut({char = '│', x = 61, y = startY+1})
	consolePut({char = '┬', x = 61, y = startY-1})
	consolePut({char = '┴', x = 61, y = startY+2})

	--[[consolePrint({string = "AC:", x = 52, y = startY, textColor = {234, 255, 0, 255}})
	consolePrint({string = playerArmor + itemGetEquipmentArmor(), x = 55, y = startY})
	consolePut({char = '|', x = 58, y = startY})
	consolePut({char = '|', x = 58, y = startY+1})
	consolePut({char = '+', x = 58, y = startY-1})
	consolePut({char = '+', x = 58, y = startY+2})]]--
	
	consolePrint({string = mapGetCurrentBranch(), x = 64, y = startY})
	if mapBranch[mapGetCurrentBranch()].floors > 1 then
		consolePrint({string = mapGetCurrentFloor(), x = 65 + string.len(mapGetCurrentBranch()), y = startY})
	end
	consolePrint({string = 'Turns:', x = 64, y = startY + 1, textColor = {222, 207, 120, 255}})
	consolePrint({string = playerTurns, x = 71, y = startY + 1})
	consolePut({char = '│', x = 80, y = startY})
	consolePut({char = '│', x = 80, y = startY+1})
	consolePut({char = '┐', x = 80, y = startY-1})
	consolePut({char = '┘', x = 80, y = startY+2})
end

--- playerDraw
--- draw the player onto the simulated console.
function playerDraw()
	consolePut({char = '@', x = playerX, y = playerY + 1, textColor = {0, 0, 0, 255}, backColor = {255, 255, 255, 255}})
end

--- playerCalcDamage
--- calculates player melee damage from equiped items and returns it.
function playerCalcDamage()
	local dam = itemGetEquipmentBonus()
	dam = dam + playerGetMod('dam')
	if dam == 0 then
		dam = math.random(1, 3)
	end
	return dam
end

--- playerIsTileFree
--- returns true if the player isn't on the specified tile.
function playerIsTileFree(x, y)
	if playerX == x and playerY == y then
		return false
	end
	return true
end

--- enable and disable fog
function playerEnableFog()
	playerFogCanCast = true
end
function playerDisableFog()
	playerFogCanCast = false
end

--- playerGetDirections
--- Asks the user to input a direction.
function playerGetDirections()
	playerGetDirection = true
	playerDirection = false
end

--- playerStopDirections
--- stops getting directions.
function playerStopDirections()
	playerGetDirection = false
end

--- playerHPMax
--- Calculates players max HP from the base health max and
--- vitality stat.
function playerHPMax()
	return playerHealthMax + (playerGetVit() * 5)
end

--- playerMPMax
--- Calculates players max MP from the base mana max and
--- mentality stat.
function playerMPMax()
	return playerManaMax + (playerGetMent() * 5)
end

--- playerAddExp
--- Adds passed experience to player experience.  If experience is above level
--- threshold then player levels up.
function playerAddExp(xp)
	playerExp = playerExp + xp
	if playerExp >= (((playerLevel)^2) * playerExpBase) then
		messageRecieve("You level up.")
		playerExp = 0
		playerLevel = playerLevel + 1
		playerMenu = 'stats'
		playerFreeStats = 5
		if playerLevel == 2 or playerLevel == 3 or playerLevel == 5 or playerLevel == 7 or playerLevel == 9 then
			playerSpellPoints = playerSpellPoints + 1
			messageRecieve("You feel like you could be stronger.")
		end
	end
end

--- playerUseTile
--- Uses the tile that the player is standing on if possible
function playerUseTile()
	local tile = mapGetTile(playerX, playerY)
	if tile.name == 'tablet' then
		playerMenu = 'tablet'
		playerMenuTablet = tile.msg
	end
end

--- playerTabletCenter
--- Calculates the starting x and y coordinates neccessary to center
--- the tablet text.
function playerTabletCenter()
	local startX = 0
	local startY = 0
	local avg = 0
	local skipped = 0

	--- Get average width of the message
	for i = 1, # playerMenuTablet do
		if playerMenuTablet[i] ~= "" then
			avg = avg + string.len(playerMenuTablet[i])
		else
			skipped = skipped + 1
		end
	end
	startX = math.floor( 40 - ((avg / (# playerMenuTablet - skipped) )/2) )

	--- Calculate starting Y based on height of the message
	startY = math.floor(10 - (#playerMenuTablet / 2))

	return startX, startY
end

--- playerLookAt
--- Finds and returns whats under the cursor when looking around
function playerLookAt()
	--- Find the tile that the player is looking at
	local tile = mapGetTile(playerActionLook[1], playerActionLook[2])
	local tileSeen = mapGetTileSeen(playerActionLook[1], playerActionLook[2])
	--- Find if there is a creature on that tile or not
	local creature = creatureGetCreatureAtTile(playerActionLook[1], playerActionLook[2])
	--- Find item if applicable
	local item = itemGetItemAt(playerActionLook[1], playerActionLook[2])
	--- Return the data to be drawn
	return tile, tileSeen, creature
end

--- playerScaling
--- Takes passed scaling table and returns bonus value from
--- scaled attributes
function playerScaling(scale)
	local bonus = 0
	if not scale then return bonus end
	for k,v in pairs(scale) do
		if k == 'vit' then
			bonus = bonus + math.floor(playerGetVit() * v)
		elseif k == 'endur' then
			bonus = bonus + math.floor(playerGetEndur() * v)
		elseif k == 'ment' then
			bonus = bonus + math.floor(playerGetMent() * v)
		elseif k == 'will' then
			bonus = bonus + math.floor(playerGetWill() * v)
		end
	end
	return bonus
end

--- playerGetVit
--- Calculates players total vit
function playerGetVit()
	return playerVit + itemGetEquipmentVal('vit')
end

--- playerGetEndur 
--- Calculates players total endur
function playerGetEndur()
	return playerEndur + itemGetEquipmentVal('vit')
end

--- playerGetMent
--- Calculates players total ment
function playerGetMent()
	return playerMent + itemGetEquipmentVal('ment')
end

--- playerGetWill
--- Calculates players total will
function playerGetWill()
	return playerWill + itemGetEquipmentVal('will')
end

--- playerIncTurns
--- Increments turns by 1
function playerIncTurns()
	playerTurns = playerTurns + 1
end

--- playerSetPrev
--- Sets player prev variable to passed value.
function playerSetPrev(pre)
	playerPrev = pre
end

--- playerHaveSpellReq
--- Checks if the player has the required spells
function playerHaveSpellReq(spell)
	if not spell.req then return true end
	for k,v in ipairs(playerSpellList) do
		if v.name == spell.req then
			return v.have
		end
	end
	return false
end

--- playerHaveSpellLevel
--- Returns true or false depending on whether the player
--- is the required level needed to learn a spell.
function playerHaveSpellLevel(spell)
	if playerLevel >= spell.level then
		return true
	else
		return false 
	end
end

--- Getters
function playerGetViewRadius() return playerViewRadius end
function playerGetPrev() return playerPrev end
function playerGetX() return playerX end
function playerGetY() return playerY end
function playerGetDirectionVar() return playerDirection end
function playerGetSpeed() return playerSpeed + playerGetMod('speed') + itemGetEquipmentVal('speed') end
function playerGetHealth() return playerHealth end
function playerGetMana() return playerMana end