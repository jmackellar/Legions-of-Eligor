--- player.lua
--- The player object.  All information, data, and actions
--- related to the player.

local playerName = 'Jesse'
local playerLevel = 1
local playerExp = 0
local playerExpBase = 7
local playerClass = 'Vagrant'

local playerHealth = 100
local playerHealthMax = 100
local playerHealthRegen = 16
local playerHealthRegenTick = 0
local playerHealthRegenCount = 3

local playerMana = 100
local playerManaMax = 100
local playerManaRegen = 21
local playerManaRegenTick = 0
local playerManaRegenCount = 3

local playerX = 5
local playerY = 5

local playerVit = 5
local playerMent = 5
local playerEndur = 5
local playerWill = 5
local playerArmor = 0
local playerSpeed = 100

local playerViewRadius = 12
local playerFogCanCast = true

local playerPrev = 'random'

local playerAction = false
local playerMenu = false

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
		if key == 'kp8' then dx = 0 dy = -1 
		elseif key == 'kp9' then dx = 1 dy = -1
		elseif key == 'kp6' then dx = 1 dy = 0
		elseif key == 'kp3' then dx = 1 dy = 1
		elseif key == 'kp2' then dx = 0 dy = 1
		elseif key == 'kp1' then dx = -1 dy = 1
		elseif key == 'kp4' then dx = -1 dy = 0
		elseif key == 'kp7' then dx = -1 dy = -1 end
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
		if key == 'kp8' then playerMoveBy(0, -1) return true
		elseif key == 'kp9' then playerMoveBy(1, -1) return true
		elseif key == 'kp6' then playerMoveBy(1, 0) return true
		elseif key == 'kp3' then playerMoveBy(1, 1) return true
		elseif key == 'kp2' then playerMoveBy(0, 1) return true
		elseif key == 'kp1' then playerMoveBy(-1, 1) return true
		elseif key == 'kp4' then playerMoveBy(-1, 0) return true
		elseif key == 'kp7' then playerMoveBy(-1, -1) return true 
		elseif key == 'kp5' then gameFlipPlayerTurn() gameSetRedrawAll() return true end
		--- actions
		if key == 'o' then playerAction = 'openclose' messageRecieve("Open which door?") 
		elseif key == 'g' then itemPickup(playerX, playerY) return true 
		elseif key == 's' and (love.keyboard.isDown('rshift') or love.keyboard.isDown('lshift')) then gameSave() love.event.push('quit') return true
		elseif key == 'i' then itemInventorySetAction('look') itemInventoryOpenFlip() return true 
		elseif key == 'd' then itemInventorySetAction('drop') itemInventoryOpenFlip() return true 
		elseif key == 'e' then itemInventorySetAction('equip') itemInventoryOpenFlip() return true 
		elseif key == 'r' then itemInventorySetAction('remove') itemInventoryOpenFlip() return true 
		elseif key == 'a' then itemInventorySetAction('apply') itemInventoryOpenFlip() return true 
		elseif key == 't' then itemInventorySetAction('throw') itemInventoryOpenFlip() return true
		elseif key == 'z' then playerMenu = 'spell'
		elseif key == 'm' then playerMenu = 'messages' 
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
		if key == 'kp8' then playerUseDoor(playerX + 0, playerY + -1)
		elseif key == 'kp9' then playerUseDoor(playerX + 1, playerY +  -1) return true
		elseif key == 'kp6' then playerUseDoor(playerX + 1, playerY +  0) return true
		elseif key == 'kp3' then playerUseDoor(playerX + 1, playerY + 1) return true
		elseif key == 'kp2' then playerUseDoor(playerX + 0, playerY + 1) return true
		elseif key == 'kp1' then playerUseDoor(playerX + -1, playerY + 1) return true
		elseif key == 'kp4' then playerUseDoor(playerX + -1, playerY + 0) return true
		elseif key == 'kp7' then playerUseDoor(playerX + -1, playerY + -1)return true end
	elseif playerMenu == 'messages' then
		if key then playerMenu = false gameSetRedrawAll() end
	elseif playerMenu == 'help' then
		if key then playerMenu = false gameSetRedrawAll() end
	elseif playerMenu == 'spell' then
		if key == 'return' or key == ' ' then
			playerMenu = false
			playerCastingSpell = false
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
	end
	if key == ' ' then
		return false
	end
	return false
end

--- playerSave
function playerSave()
	local p = "playersave.lua"
	local pf = love.filesystem.newFile(p)
	local t = {playerX = playerX, playerY = playerY, playerHealth = playerHealth, playerHealthMax = playerHealthMax, 
				playerMana = playerMana, playerManaMax = playerManaMax, playerVit = playerVit, playerMent = playerMent, 
				playerEnd = playerEnd, playerWill = playerWill, mapCurrentBranch = mapGetCurrentBranch(),
				mapCurrentFloor = mapGetCurrentFloor()}
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
		playerEnd = t1.playerEnd
		playerWill = t1.playerWill 
		mapSetCurrentBranch(t1.mapCurrentBranch)
		mapSetCurrentFloor(t1.mapCurrentFloor)
		return true
	end
	return false
end

--- playerCastSpell
--- Casts spell i
function playerCastSpell(i)
	--- Check if the spell exists and the player is able to cast it
	if gameClasses[playerClass].spells[i] then
		if gameClasses[playerClass].spells[i].level <= playerLevel then
			--- Player selected a spell and meets level requirements
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
					if spell.name == 'Roll' then playerSpellRoll(spell) end
					if spell.name == 'Shoutout' then playerSpellShoutout(spell) end
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
				return false
			end
		end
	end
	return false
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
	for xx = math.max(1, sx - spell.dist), math.min(mapGetWidth(), sx + spell.dist) do
		for yy = math.max(1, sy - spell.dist), math.min(mapGetHeight(), sy + spell.dist) do
			creatureAddModAt({mod = 'armor', val = spell.armor, turn = spell.turns}, xx , yy)
		end
	end
	messageRecieve(spell.castmsg)
	playerCastFog()
	gameSetRedrawAll()
end

--- playerUseDoor
--- opens or closes a target door.  If a door exists that is.
function playerUseDoor(x, y)
	if mapCheckTileAt(x, y, 'closeddoor') then
		mapSwitchDoor(x, y)
		messageRecieve("You open the door.")
	elseif mapCheckTileAt(x, y, 'opendoor') then
		mapSwitchDoor(x, y)
		messageRecieve("You close the door.")
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
		table.insert(playerModifiers, {mod = modifier.mod, turn = modifier.turn, val = modifier.val, msgend = modifier.msgend})
	end
end

--- playerModifierUpdate
--- Ticks down all modifiers per turn.
function playerModifierUpdate()
	for i = # playerModifiers, 1, -1 do
		playerModifiers[i].turn = playerModifiers[i].turn - 1
		if playerModifiers[i].turn <= 0 then
			messageRecieve(playerModifiers[i].msgend)
			table.remove(playerModifiers, i)
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
		playerMana = playerMana + math.ceil(playerWill / 2)
		if playerMana > playerMPMax() then
			playerMana = playerMPMax()
		end
	end
	if playerHealthRegenTick <= 0 then
		playerHealthRegenTick = playerHealthRegen
		playerHealth = playerHealth + math.ceil(playerEndur / 2)
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
		damred = damred + math.random(0, 1)
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

--- playerDrawMenu
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
			consolePrint({string = "I - View Inventory", x = 2, y = 12})
			consolePrint({string = "E - Equip Item", x = 2, y = 13})
			consolePrint({string = "R - Remove Equipment", x = 2, y = 14})
			consolePrint({string = "A - Apply Item", x = 2, y = 15})
			consolePrint({string = "T - Throw Item", x = 2, y = 16})
			consolePrint({string = "G - Pick Up Item", x = 2, y = 17})
			consolePrint({string = "D - Drop Item", x = 2, y = 18})
			consolePrint({string = "O - Use Door", x = 2, y = 19})
			consolePrint({string = "Z - Cast Spell", x = 2, y = 20})
		
			consolePrint({string = "M - View Recent Messages", x = 2, y = 23})			
			consolePrint({string = "? - This Help Screen", x = 2, y = 24})
		elseif playerMenu == 'spell' and not playerCastingSpell then
			consoleFlush()
			local y = 3
			local alpha = 1
			for i = 1, # gameClasses[playerClass].spells do
				local spell = gameClasses[playerClass].spells[i]
				consolePrint({string = "Cast which spell?  a-z select spell, return or spacebar to cancel.", x = 1, y = 1})
				if spell.level <= playerLevel then
					consolePrint({string = alphabet[alpha]:gsub("^%l", string.upper) .. " - " .. spell.name .. ", Mana:" .. spell.mana, x = 2, y = y})
					consolePrint({string = spell.desc, x = 6, y = y + 1})
					y = y + 2
					alpha = alpha + 1
				end
			end
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
	consolePrint({string = "----------------------------------------------------------------------------------", x = 1, y = startY - 1})
	consolePrint({string = "----------------------------------------------------------------------------------", x = 1, y = startY + 2})
	--- Hud
	consolePrint({string = playerName, x = 2, y = startY})
	consolePrint({string = "Level " .. playerLevel .. " " .. playerClass, x = 2, y = startY + 1, textColor = {222, 207, 120, 255}})
	--consolePrint({string = playerLevel .. " " .. playerClass, x = 8, y = startY + 1})
	
	consolePrint({string = "HP:", x = 22, y = startY, textColor = {255, 0, 0, 255}})
	consolePrint({string = playerHealth .. "/" .. playerHPMax(), x = 25, y = startY})
	consolePrint({string = "MP:", x = 22, y = startY + 1, textColor = {0, 0, 255, 255}})
	consolePrint({string = playerMana .. "/" .. playerMPMax(), x = 25, y = startY + 1})
	
	consolePrint({string = "Armor:", x = 12, y = startY, textColor = {234, 255, 0, 255}})
	consolePrint({string = playerArmor + itemGetEquipmentArmor(), x = 19, y = startY})
	
	consolePrint({string = "Vitality :", x = 34, y = startY, textColor = {224, 119, 119, 255}})
	consolePrint({string = playerVit, x = 44, y = startY})
	consolePrint({string = "Mentality:", x = 34, y = startY+1, textColor = {119, 119, 224, 255}})
	consolePrint({string = playerMent, x = 44, y = startY+1})
	consolePrint({string = "Endurance:", x = 47, y = startY, textColor = {119, 224, 119, 255}})
	consolePrint({string = playerEndur, x = 57, y = startY})
	consolePrint({string = "Willpower:", x = 47, y = startY+1, textColor = {213, 115, 240, 255}})
	consolePrint({string = playerWill, x = 57, y = startY+1})	
	
	consolePrint({string = "Location:", x = 60, y = startY, textColor = {222, 207, 120, 255}})
	consolePrint({string = mapGetCurrentBranch() .. ", " .. mapGetCurrentFloor(), x = 69, y = startY})
	consolePrint({string = "Experience:", x = 60, y = startY+1, textColor = {222, 207, 120, 255}})
	consolePrint({string = playerExp .. "/" .. (((playerLevel)^2) * playerExpBase), x = 71, y = startY+1})
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
	if dam == 0 then
		dam = math.random(1, 3)
	end
	print(dam)
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
	return playerHealthMax + (playerVit * 5)
end

--- playerMPMax
--- Calculates players max MP from the base mana max and
--- mentality stat.
function playerMPMax()
	return playerManaMax + (playerMent * 5)
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
		playerVit = playerVit + gameClasses[playerClass].levelup.vit
		playerEndur = playerEndur + gameClasses[playerClass].levelup.endur
		playerMent = playerMent + gameClasses[playerClass].levelup.ment
		playerWill = playerWill + gameClasses[playerClass].levelup.will
	end
end

--- Getters
function playerGetViewRadius() return playerViewRadius end
function playerGetPrev() return playerPrev end
function playerGetX() return playerX end
function playerGetY() return playerY end
function playerGetDirectionVar() return playerDirection end
function playerGetSpeed() return playerSpeed + playerGetMod('speed') end
function playerGetHealth() return playerHealth end