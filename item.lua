--- item.lua
--- Items and player inventory

local items = { }
local itemsInventory = { }
local itemsInventoryMax = 18

local itemsIdentified = { }

local itemsStartingEquipment = { dagger = {data = gameItems.dagger, x = 1, y = 1},
                              sandels = {data = gameItems.sandels, x = 1, y = 1}, }
local itemsEquipment = {head = false, 
						body = false,
						back = false, 
						legs = false, 
						hands = false, 
						feet = itemsStartingEquipment.sandels, 
						weapon = itemsStartingEquipment.dagger
						}
local itemsEquipmentOrder = {'head', 'body', 'back', 'legs', 'hands', 'feet', 'weapon'}

local itemsAlphabet = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}

local itemsInventoryOpen = false
local itemsInventoryAction = 'look'
local itemsInventoryDrawInventoryOff = false
local itemsInventorySort = {'ammo', 'weapons', 'armor', 'scrolls', 'potions', 'useables'}

--- itemStartingEquipmentClass
--- Sets up class specific starting equipment
function itemStartingEquipmentClass(class)
	if gameClasses[class] then
		for k,v in pairs(gameClasses[class].startingEquipment) do
			if v and gameItems[v] then
				itemsEquipment[k] = {data = gameItems[v], x = 1, y = 1}
			end
		end
	end
end

--- itemStartingInventoryClass
--- Sets up class specific starting inventory
function itemStartingInventoryClass(class)
	if gameClasses[class] then
		for i = 1, # gameClasses[class].startingItems do
			local item = gameClasses[class].startingItems[i]
			table.insert(itemsInventory, {data = gameItems[item], x = 1, y = 1})
		end
	end
end

--- itemDraw
--- draws items onto the map.
function itemDraw()
	for i = 1, # items do
		if mapIsLit(items[i].x, items[i].y) then
			consolePut({char = items[i].data.char, x = items[i].x, y = items[i].y + 1, backColor = items[i].data.backColor, textColor = items[i].data.textColor})
		end
	end
end

--- itemKeypressed
--- inventory management keypresses.
function itemKeypressed(key)
	if itemsInventoryOpen then
		-------------------------
		--- Looking at inventory.
		if itemsInventoryAction == 'look' and key then
			if key == 'return' or key == ' ' then
				itemInventoryOpenFlip()
			else
				if itemKeyIsLetter(key) and itemsInventory[itemKeyIsLetter(key)] then 
					itemsInventoryAction = 'desc'
					itemsInventoryDesc = itemKeyIsLetter(key)
				end
			end
		-------------------------
		--- Describing an item
		elseif itemsInventoryAction == 'desc' then 
			if key then 
				itemsInventoryAction = 'look'
				gameSetRedrawAll()
			end
		-------------------------
		--- Dropping an item from inventory.
		elseif itemsInventoryAction == 'drop' then
			if key == 'return' or key == ' ' then
				itemInventoryOpenFlip()
				messageRecieve("Never mind.")
			else
				if itemKeyIsLetter(key) then itemDropFromInventory(itemKeyIsLetter(key)) end
			end
		-------------------------
		--- Equipping an item from inventory.
		elseif itemsInventoryAction == 'equip' then
			if key == 'return' or key == ' ' then
				itemInventoryOpenFlip()
				messageRecieve("Never mind.")
			else
				if itemKeyIsLetter(key) then itemEquipFromInventory(itemKeyIsLetter(key)) end
			end
		-------------------------
		--- Removing an equipped item.
		elseif itemsInventoryAction == 'remove' then
			if key == 'return' or key == ' ' then
				itemInventoryOpenFlip()
				messageRecieve("Never mind.")
			else
				if itemKeyIsLetter(key) then
					local letter = itemKeyIsLetter(key)
					itemRemoveFromEquipment(letter)
				end
				itemInventoryOpenFlip()
			end
		------------------------
		--- Applying an item.
		elseif itemsInventoryAction == 'apply' then
			if key == 'return' or key == ' ' then
				itemInventoryOpenFlip()
				messageRecieve("Never mind.")
			else
				if itemKeyIsLetter(key) then
					local letter = itemKeyIsLetter(key)
					itemApplyFromInventory(letter)
				end
				itemInventoryOpenFlip()
			end
		------------------------
		--- Throwing an item.
		elseif itemsInventoryAction == 'throw' then
			if key == 'return' or key == ' ' then
				itemInventoryOpenFlip()
				messageRecieve("Never mind.")
			else
				if itemKeyIsLetter(key) then
					local letter = itemKeyIsLetter(key)
					itemThrowFromInventory(letter)
				end
			end
		------------------------
		---- Throw Item #2
		elseif itemsInventoryAction == 'throw2' then
			if key == 'return' or key == ' ' then
				itemInventoryOpenFlip()
				playerStopDirections()
				messageRecieve("Never mind.")
			else
				playerKeypressed(key)
				itemThrowUpdate()
				itemInventoryOpenFlip()
			end
		end
		return true
	end
	return false
end

--- itemDrawInventory
--- draws the inventory screen.
--- This shits a disgusting mess.
function itemDrawInventory()
	if itemsInventoryDrawInventoryOff then
		return 
	end
	local startX = 1
	local startY = 2
	-------------------
	--- Inventory
	for x = startX + 2, startX + 28 do
		consolePut({char = '─', textColor = {237, 222, 161, 255}, x = x, y = startY})
	end
	consolePut({char = '┌', x = startX + 1, y = startY, textColor = {237, 222, 161, 255}})
	consolePut({char = '┐', x = startX + 29, y = startY, textColor = {237, 222, 161, 255}})
	consolePrint({string = "Inventory", textColor = {237, 222, 161, 255}, x = startX + 11, y = startY})
	startX = startX + 2
	local cursort = ''
	local drawY = startY - 1
	for i = 1, # itemsInventory do		
		--- update cursort
		if cursort ~= itemsInventory[i].data.sort then
			cursort = itemsInventory[i].data.sort
			consolePut({char = '│', textColor = {237, 222, 161, 255}, x = startX - 1, y = startY +(drawY)})
			consolePut({char = '│', textColor = {237, 222, 161, 255}, x = startX + 27, y = startY +(drawY)})
			consolePrint({string = "                           ", textColor = {237, 222, 161, 255}, x = startX, y = startY + (drawY)})
			consolePrint({string = cursort:gsub("^%l", string.upper) .. " ", x = startX + 1, y = startY + (drawY)})
			drawY = drawY + 1
		end
		--- First put blank line in to make background box.
		consolePut({char = '│', textColor = {237, 222, 161, 255}, x = startX - 1, y = startY +(drawY)})
			consolePut({char = '│', textColor = {237, 222, 161, 255}, x = startX + 27, y = startY +(drawY)})
			consolePrint({string = "                           ", textColor = {237, 222, 161, 255}, x = startX, y = startY + (drawY)})
		--- Item name and inventory slot letter.
		local str = " "
		if itemsInventoryAction == 'remove' then
			str = str .. "X) "
		else
			str = str .. itemsAlphabet[i]:gsub("^%l", string.upper) .. ") "
		end
		consolePrint({string = str, textColor = {234, 255, 0, 255}, x = startX + 2, y = startY + (drawY)})
		str = ""
		if itemsInventory[i].data.idname and itemIsIdentified(itemsInventory[i]) then
			str = str .. itemsInventory[i].data.idname:gsub("^%l", string.upper)
		else
			str = str .. itemsInventory[i].data.name:gsub("^%l", string.upper)
		end
		--- item name color
		local tColor = {255, 255, 255, 255}
		if itemsInventory[i].data.isMagic then
			tColor = magicItems.mColors.invColor
		elseif itemsInventory[i].data.isQuest then
			tColor = magicItems.qColors.invColor
		end
		consolePrint({string = str, textColor = tColor, x = startX + 6, y = startY + (drawY)})
		drawY = drawY + 1
	end
	consolePut({char = '└', x = startX - 1, y = startY + drawY, textColor = {237, 222, 161, 255}})
	consolePut({char = '┘', x = startX + 27, y = startY + drawY, textColor = {237, 222, 161, 255}})
	for x = startX, startX + 26 do
		consolePut({char = '─', textColor = {237, 222, 161, 255}, x = x, y = startY + drawY})
	end
	-------------------
	--- Equipment 		
	local i = 0
	startX = startX - 10
	for x = startX + 49, startX + 48 + 37 do
		consolePut({char = '─', x = x, y = startY, textColor = {237, 222, 161, 255}})
	end
	consolePut({char = '┌', x = startX + 48, y = startY, textColor = {237, 222, 161, 255}})
	consolePut({char = '┐', x = startX + 48 + 38, y = startY, textColor = {237, 222, 161, 255}})
	consolePrint({string = "Equipment", textColor = {237, 222, 161, 255}, x = startX + 48 + 15, y = startY})
	for j = 1, # itemsEquipmentOrder do
		for k, v in pairs(itemsEquipment) do
			if k == itemsEquipmentOrder[j] then
				--- First increment counter i and put blank line in to make background box.
				i = i + 1
				consolePut({char = '│', x = startX + 48, y = startY + i, textColor = {237, 222, 161, 255}})
				consolePut({char = '│', x = startX + 86, y = startY + i, textColor = {237, 222, 161, 255}})
				consolePrint({string = "                                     ", textColor = {237, 222, 161, 255}, x = startX + 49, y = startY + (i)})
				--- Equipment slot and item name.
				local add = "  "
				if k == 'weapon' then
					--- Change add to 0
					add = ""
				elseif k == 'hands' then
					--- Change add to 1
					add = " "
				end
				local str = ""
				--- If inventory action is remove then add letters in front of the items instead of the equipment slot name.
				str = str .. (k:gsub("^%l", string.upper))
				str = str .. add
				consolePrint({string = str, x = startX + 50, y = startY + i})
				str = ""
				if itemsInventoryAction == 'remove' then
					str = str .. "" .. itemsAlphabet[i]:gsub("^%l", string.upper) .. ")"
				else
					str = str .. ": "
				end
				consolePrint({string = str, textColor = {234, 255, 0, 255}, x = startX + 57, y = startY + i})
				str = ""
				--- If v is a false or nil then don't add anything to the string.  Else add the item name.
				if v then
					str = str .. (itemGetName(v):gsub("^%l", string.upper))
				end
				local tColor = {255, 255, 255, 255}
				if v and v.data.isMagic then
					tColor = magicItems.mColors.invColor
				end
				consolePrint({string = str, textColor = tColor, x = startX + 59, y = startY + (i)})
			end
		end
	end
	for x = startX + 49, startX + 48 + 37 do
		consolePut({char = '─', x = x, y = startY + i + 1, textColor = {237, 222, 161, 255}})
	end
	consolePut({char = '└', x = startX + 48, y = startY + i + 1, textColor = {237, 222, 161, 255}})
	consolePut({char = '┘', x = startX + 48 + 38, y = startY + i + 1, textColor = {237, 222, 161, 255}})
	if itemsInventoryAction == 'desc' then
		itemDrawDescription()
	end
end

--- itemDrawDescription
--- Draws items description box with all stats and information.
function itemDrawDescription()
	--- locals
	local sx = 15
	local sy = 3
	local width = 50
	local height = 19
	local item = itemsInventory[itemsInventoryDesc]
	local name = item.data.name
	local nColor = {255, 255, 255, 255}
	if item.data.idname and itemIsIdentified(item) then
		name = item.data.idname
	end
	if item.data.isMagic then
		nColor = magicItems.mColors.invColor
	end

	--- Window box
	for x = sx, sx + width do
		for y = sy, sy + height do
			consolePut({char = ' ', x = x, y = y})
			if x < sx + 1 or x > sx + width - 1 then
				consolePut({char = '│', x = x, y = y, textColor = {237, 222, 161, 255}})
			end
			if y < sy + 1 or y > sy + height - 1 then
				consolePut({char = '─', x = x, y = y, textColor = {237, 222, 161, 255}})
			end
		end
	end
	consolePut({char = '┌', x = sx, y = sy, textColor = {237, 222, 161, 255}})
	consolePut({char = '└', x = sx, y = sy + height, textColor = {237, 222, 161, 255}})
	consolePut({char = '┐', x = sx + width, y = sy, textColor = {237, 222, 161, 255}})
	consolePut({char = '┘', x = sx + width, y = sy + height, textColor = {237, 222, 161, 255}})

	--- Information
	consolePrint({string = name:gsub("^%l", string.upper), x = sx + 3, y = sy + 2, textColor = nColor})
	consolePut({char = item.data.char, x = sx + 5 + string.len(name), y = sy + 2, textColor = item.data.textColor, backColor = item.data.backColor})
	consolePrint({string = item.data.sort:gsub("^%l", string.upper), x = sx + 3, y = sy + 3})
	if item.data.slot and item.data.slot ~= 'weapon' then
		consolePrint({string = ': ' .. item.data.slot:gsub("^%l", string.upper), x = sx + 4 + string.len(item.data.sort), y = sy + 3})
	end

	--- Attack information
	if item.data.sort == 'weapons' then
		local dMin = ((1 + item.data.damage.bonus) * item.data.damage.dice)
		local dMax = ((item.data.damage.sides + item.data.damage.bonus) * item.data.damage.dice)
		consolePrint({string = 'Attack Damage', x = sx + 3, y = sy + 6, textColor = {234, 255, 0, 255}})
		consolePrint({string = '(' .. dMin .. '-' .. dMax .. ')', x = sx + 5, y = sy + 7})
	elseif item.data.sort == 'armor' then
		local arm = playerGetArmor() + itemGetEquipmentArmor()
		local drmin = 0
		local drmax = 0
		for i = 1, arm do
			if i < (arm * 0.55) then
				drmin = drmin + 1
			end
			drmax = drmax + 1
		end
		consolePrint({string = 'Armor:', x = sx + 3, y = sy + 6, textColor = {234, 255, 0, 255}})
		consolePrint({string = item.data.armor, x = sx + 10, y = sy + 6})
		consolePrint({string = 'Damage Reduction', x = sx + 3, y = sy + 7, textColor = {234, 255, 0, 255}})
		consolePrint({string = '(' .. drmin .. '-' .. drmax .. ')', x = sx + 5, y = sy + 8})
	end

	--- Magic properties
	local i = 0
	if item.data.mPrefix and itemIsIdentified(item) then
		consolePrint({string = 'Affixes', x = sx + 30, y = sy + 2})
		for k,v in pairs(item.data.mPrefix.val) do
			if magicItems.keyToString[k] then
				consolePrint({string = magicItems.keyToString[k].key .. ': ' .. v, x = sx + 27, y = sy + 3 + i, textColor = magicItems.keyToString[k].color})
			else
				consolePrint({string = k .. ': ' .. v, x = sx + 27, y = sy + 3 + i})
			end
			i = i + 1
		end
	end

	--- Description
	if item.data.desc then
		for i = 1, # item.data.desc do
			consolePrint({string = item.data.desc[i], x = sx + 3, y = sy + 12 + i})
		end
	end
end

--- itemThrowUpdate
--- Updates and checks for item throw.
function itemThrowUpdate()
	local dir = playerGetDirectionVar()
	local item = itemsThrowItem 
	if dir then
		playerStopDirections()
		--- throw in the direction
		local x = playerGetX()
		local y = playerGetY()
		local dam = love.math.random(1,3)
		if item.data.throwdam then
			dam = love.math.random(item.data.throwdam[1], item.data.throwdam[2])
		end
		for i = 1, 10 do
			x = x + dir.dx
			y = y + dir.dy
			if not creatureIsTileFree(x, y) then
				creatureAttackedByPlayer(x, y, dam, item.data.throwmsg)
				break
			end
			if not mapGetWalkThru(x + dir.dx, y + dir.dy) then
				break
			end
		end
		for i = 1, # itemsInventory do
			if itemsInventory[i] == item then
				local chance = 100
				if item.throwbreakchance then
					chance = chance - item.throwbreakchance
				else
					chance = chance - 25
				end
				if not itemsInventory[i].data.breakonthrow and love.math.random(1, 100) <= chance then
					table.insert(items, {x = x, y = y, data = item.data})
				else
					messageRecieve("Your " .. itemGetName(item) .. " broke from the throw.")
				end
				table.remove(itemsInventory, i)
			end
		end
		gameFlipPlayerTurn()
	end
end

--- itemThrowFromInventory
--- Throws an item from the inventory in target direction.
function itemThrowFromInventory(letter)
	if not itemsInventory[letter] then return end
	local item = itemsInventory[letter]
	local dir = false
	itemsThrowItem = item
	--- get direction to throw
	playerGetDirections()
	dir = playerGetDirectionVar()
	itemsInventoryAction = 'throw2'
	itemsInventoryDrawInventoryOff = true
	gameSetRedrawAll()
	messageRecieve("Throw " .. item.data.prefix .. itemGetName(item) .. " in which direction?  Numpad to aim, any other key to cancel.")
end

--- itemApplyFromInventory
--- applies an item from the inventory if possible.
function itemApplyFromInventory(letter)
	if not itemsInventory[letter] then return end
	local item = itemsInventory[letter]
	local msg = ""
	local used = false
	-----------------------------------
	----------- Item Types
	------------------------------
	------------------------
	if item.data.type == 'healplayer' then 
		playerHeal(item.data.health[1], item.data.health[2]) 
		used = true
	elseif item.data.type == 'managainplayer' then
		playerManaGain(item.data.mana[1], item.data.mana[2])
		used = true
	elseif item.data.type == 'speed' then
		playerAddMod({mod = 'speed', turn = item.data.turns, val = item.data.speed, msgend = item.data.msgend})
		used = true
	elseif item.data.type == 'teleport' then
		local mana = item.data.manacost or 0
		if playerGetMana() >= mana then
			messageRecieve(item.data.msg)
			playerManaGain(mana * -1, mana * -1)
			playerSetPrev('spawn')
			mapChangeBranch(item.data.teleport)
		else
			messageRecieve(item.data.nomanamsg)
		end
	end
	if used then 
		msg = item.data.msg
		messageRecieve(msg)
		if item.data.idname then
			itemAddIdentify(item)
		end
		if item.data.useonce then
			table.remove(itemsInventory, letter)
		end
	end
end

--- itemRemoveFromEquipment
--- removes an equipped item if it exists.  Places in inventory if room, else
--- items is dropped to the floor at the player's feet.
function itemRemoveFromEquipment(letter)
	local i = 0
	for j = 1, # itemsEquipmentOrder do
		for k, v in pairs(itemsEquipment) do
			if k == itemsEquipmentOrder[j] then
				i = i + 1
				if letter == i then
					if itemsEquipment[k] then
						if # itemsInventory < itemsInventoryMax then
							table.insert(itemsInventory, itemsEquipment[k])
							messageRecieve("You remove your " .. itemGetName(itemsEquipment[k]) .. " and place it in your bag.")
						else
							table.insert(items, {x = playerGetX(), y = playerGetY(), data = itemsEquipment[k].data})
							messageRecieve("You remove your " .. itemGetName(itemsEquipment[k]) .. " and place it on the floor.")
						end
						itemsEquipment[k] = false		
						gameFlipPlayerTurn()
						break
					else
						messageRecieve("There is nothing to remove there.")
						return
					end
				end
			end
		end
	end
end

--- itemEquipFromInventory
--- equips item i from inventory.  Switches equipment if an item
--- was already equipped in the player's item slot.
function itemEquipFromInventory(i)
	if not itemsInventory[i] then return end
	for k, v in pairs(itemsEquipment) do
		--- Found slot.  Remove equipping item from inventory and 
		--- place into a temporary variable.
		if k == itemsInventory[i].data.slot then
			local item = itemsInventory[i]
			table.remove(itemsInventory, i)
			--- If the slot is already occupied then remove item from the slot
			--- and return it to the player's inventory.
			if v and v.data.slot == item.data.slot then
				table.insert(itemsInventory, v)
				messageRecieve("You remove your " .. itemGetName(v) .. ".")
			end
			--- Place item from temp variable into equipment slot.
			itemsEquipment[k] = item
			messageRecieve("You equip your " .. itemGetName(itemsEquipment[k]) .. ".")
			itemAddIdentify(item)
			--- item was equipped.  Set game to redraw all, close equip menu, and break from for loop.
			itemInventoryOpenFlip()
			gameSetRedrawAll()
			gameFlipPlayerTurn()
			break
		end
	end
end

--- itemDropFromInventory
--- drops item i from inventory onto the map.
function itemDropFromInventory(i)
	if itemsInventory[i] then
		messageRecieve("You dropped " .. itemsInventory[i].data.prefix .. itemGetName(itemsInventory[i]) .. ".")
		--- If the player drops an item onto an identification stand
		mapUseIdentificationStand(playerGetX(), playerGetY(), itemsInventory[i])
		--- Remove item from inventory and add to the ground
		table.insert(items, {x = playerGetX(), y = playerGetY(), data = itemsInventory[i].data})
		table.remove(itemsInventory, i)
		itemInventoryOpenFlip()
		gameFlipPlayerTurn()
	end
end

--- itemKeyIsLetter
--- tests if the key variable is a letter and if so returns the index of the letter.
--- else returns false.
function itemKeyIsLetter(key)
	for i = 1, # itemsAlphabet do
		if key == itemsAlphabet[i] then
			return i
		end
	end
	return false
end

--- itemPickup
--- picks items up from tile and places them in inventory.
function itemPickup(x, y)
	--- check if the player has room in his inventory.  If so then continue and pick up the item.
	if # itemsInventory < itemsInventoryMax then
		local is = { }
		for i = 1, # items do
			if items[i].x == x and items[i].y == y then
				table.insert(is, {i = i, item = items[i]})
			end
		end
		for i = # is, 1, -1 do
			if # itemsInventory >= itemsInventoryMax then
				messageRecieve("You can't fit the rest in your bag.")
				return
			end
			table.remove(items, is[i].i)
			table.insert(itemsInventory, is[i].item)
			messageRecieve("You picked up " .. is[i].item.data.prefix .. itemGetName(is[i].item) .. ".")
			table.remove(is, i)
		end
		gameFlipPlayerTurn()
	else
		messageRecieve("You don't have enough room in your bag to pick anything up.")
	end
	gameSetRedrawAll()
end

--- itemPlace
--- Takes passed item data and places it on the map
function itemPlace(item, x , y)
	table.insert(items, {data = item, x = x, y = y})
end

--- itemGenerate
--- generates items based on current branch.
function itemGenerate()
	local branch = mapBranch[mapGetCurrentBranch()]
	local amnt = love.math.random(branch.minItems, branch.maxItems)
	local placed = 0
	items = { }
	--- place guaranteed items
	for i = 1, # branch.items do
		local mx = math.ceil(amnt * (branch.items[i].perc / 100))
		placed = 0
		repeat
			local x = love.math.random(1, mapGetWidth())
			local y = love.math.random(1, mapGetHeight())
			if mapGetWalkThru(x, y) then
				placed = placed + 1
				table.insert(items, {data = gameItems[branch.items[i].name], x = x, y = y})
			end
		until placed >= mx
	end
	--- place extra items at a chance
	local itemMax = branch.maxExtraItems or 0
	for i = 1, (love.math.random(0, branch.maxExtraItems)) do
		if love.math.random(1, 100) <= branch.extraItemsChance then
			local placed = false
			repeat
				local x = love.math.random(1, mapGetWidth())
				local y = love.math.random(1, mapGetHeight())
				if mapGetWalkThru(x, y) then
					placed = true
					local item = love.math.random(1, # branch.extraItems)
					table.insert(items, {data = gameItems[branch.extraItems[item]], x = x , y = y})
				end
			until placed
		end
	end
	--- place guaranteed items
	if branch.guaranteedItems then
		local gItems = branch.guaranteedItems
		for i = 1, # gItems do
			local placed = false
			repeat
				local x = gItems[i].x or love.math.random(1, mapGetWidth())
				local y = gItems[i].y or love.math.random(1, mapGetHeight())
				if mapGetWalkThru(x, y) then
					placed = true
					table.insert(items, {data = gameItems[gItems[i].name], x = x, y = y})
				end
			until placed
		end
	end
	itemGenerateSpecial()
	gameSetRedrawItem()
end

--- itemGenerateSpecial
--- Generates random magical items and places them on the map.
------ Important Branch Variables ------
--- branch.
--- \--magicItemsTier
--- \--magicChance
--- \--maxMagicItems
function itemGenerateSpecial()
	local branch = mapBranch[mapGetCurrentBranch()]
	if branch.magicItemsTier then
		--- Roll for every item chance
		for itemroll = 1, branch.maxMagicItems do
		
			--- Roll if the item can be created.
			if math.random(1, 100) <= branch.magicChance then

				local itemOrig = magicItems.mItems[math.random(1, #magicItems.mItems)]
				local prefix = magicItems.mPrefix[itemOrig.type][math.random(1, #magicItems.mPrefix[itemOrig.type])]
				
				--- Create a new item out of the orig
				local item = { }
				itemOrig = gameItems[itemOrig.name]
				for k,v in pairs(itemOrig) do
					item[k] = v
				end
				
				--- Apply prefix values to the item
				for k,v in pairs(prefix.val) do
					local val = v * branch.magicItemsTier
					if item[k] then
						item[k] = item[k] + val
					else
						item[k] = val
					end
				end

				--- Point back to original prefix
				item['mPrefix'] = prefix
				
				--- Apply color changes
				item.backColor = magicItems.mColors.backColor
				item.textColor = magicItems.mColors.textColor
				
				--- Fix idname and name
				item.idname = prefix.name .. " " .. item.name
				item.name = 'magic ' .. item.name
				
				--- set a flag letting the item know that its magical
				item.isMagic = true
				
				--- Now place item on map
				local placed = false
				repeat
					local x = love.math.random(1, mapGetWidth())
					local y = love.math.random(1, mapGetHeight())
					if mapGetWalkThru(x, y) then
						placed = true
						table.insert(items, {data = item, x = x , y = y})
					end
				until placed
					
			end
		
		end
		
	end
end

--- itemSave
--- saves items of current map to file.
function itemSave(pre)
	local i = pre .. "items.lua"
	local e = "equipment.lua"
	local ii = "inventory.lua"
	local id = "identified.lua"
	local ifi = love.filesystem.newFile(i)
	local iif = love.filesystem.newFile(ii)
	local ie = love.filesystem.newFile(e)
	local idf = "identified.lua"
	love.filesystem.write(id, Ser(itemsIdentified))
	love.filesystem.write(i, Ser(items))
	love.filesystem.write(ii, Ser(itemsInventory))
	love.filesystem.write(e, Ser(itemsEquipment))
end

--- itemLoad
--- loads items of current map from file.
function itemLoad(pre)
	local i = pre .. "items.lua"
	local ii = "inventory.lua"
	local e = "equipment.lua"
	local id = "identified.lua"
	local t = false
	if love.filesystem.exists(i) then
		local c1 = love.filesystem.load(i)
		items = c1()
		t = true
	end
	if love.filesystem.exists(ii) then
		local c2 = love.filesystem.load(ii)
		itemsInventory = c2()
		t = true
	end
	if love.filesystem.exists(e) then
		local c3 = love.filesystem.load(e)
		itemsEquipment = c3()
		t = true
	end
	if love.filesystem.exists(id) then
		local c4 = love.filesystem.load(id)
		itemsIdentified = c4()
		t = true
	end
	return t
end

--- itemDidPlayerWalkOverItem
--- checks if the player walked over the item and if so display
--- a message about what the player is standing on top of.
function itemDidPlayerWalkOverItem(x, y)
	local is = { }
	for i = 1, # items do
		if items[i].x == x and items[i].y == y then
			table.insert(is, {itemGetName(items[i]), items[i].data.singular})
		end
	end
	if # is == 1 then
		messageRecieve("You see here " .. is[1][2] .. is[1][1] .. ".")
	elseif # is == 2 then
		messageRecieve("There are a couple items here.")
	elseif # is == 3 then
		messageRecieve("There are a few items here.")
	elseif # is >= 4 and # is <= 10 then
		messageRecieve("There are several items here.")
	elseif # is > 10 then
		messageRecieve("There are a lot of items here.")
	end
end

--- itemInventoryOpenFlip
--- flips itemsInventoryOpen to either true or false
function itemInventoryOpenFlip()
	itemSortInventory()
	if itemsInventoryOpen then
		itemsInventoryOpen = false
		messageRecieve("")
	else
		itemsInventoryOpen = true
		itemsInventoryDrawInventoryOff = false
		if itemsInventoryAction == 'look' then
			messageRecieve("Press any key to close inventory and equipment window.")
		elseif itemsInventoryAction == 'drop' then
			messageRecieve("Drop which item?  a-z select item to drop, enter or space to cancel.")
		elseif itemsInventoryAction == 'equip' then
			messageRecieve("Equip which item?  a-z select item to equip, enter or space to cancel.")
		elseif itemsInventoryAction == 'remove' then
			messageRecieve("Remove which item?  a-z select item to remove, enter or space to cancel.")
		elseif itemsInventoryAction == 'apply' then
			messageRecieve("Apply which item?  a-z select item to apply, enter or space to cancel.")
		elseif itemsInventoryAction == 'throw' then
			messageRecieve("Throw which item?  a-z select item to throw, enter or space to cancel.")
		end
	end
	gameSetRedrawAll()
end

--- itemInventorySetAction
--- sets the itemsInventoryAction string.
function itemInventorySetAction(act)
	itemsInventoryAction = act
end

--- itemGetEquipmentDamage
--- returns equipment damage added up from all equipped items.
function itemGetEquipmentBonus()
	local dam = 0
	for k, v in pairs(itemsEquipment) do
		if v and v.data.damage then
			for i = 1, v.data.damage.dice do
				dam = dam + love.math.random(1, v.data.damage.sides)
			end
			dam = dam + v.data.damage.bonus
			if v.data.damagebonus then
				dam = dam + v.data.damagebonus
			end
		end
	end
	return dam
end

--- itemGetEquipmentDamageRange
--- Returns the min and max of equipment damage
function itemGetEquipmentDamageRange()
	local dammin = 0
	local dammax = 0
	for k, v in pairs(itemsEquipment) do
		if v and v.data.damage then
			for i = 1, v.data.damage.dice do
				dammin = dammin + 1
				dammax = dammax + v.data.damage.sides
			end
			dammin = dammin + v.data.damage.bonus
			dammax = dammax + v.data.damage.bonus
			if v.data.damagebonus then
				dammin = dammin + v.data.damagebonus
				dammax = dammax + v.data.damagebonus
			end
		end
	end
	return dammin, dammax
end

--- itemGetEquipmentVal
--- returns passed target val sum of all equiped items
function itemGetEquipmentVal(val)
	local ret = 0
	for kk,vv in pairs(itemsEquipment) do
		if vv and vv.data then
			for k, v in pairs(vv.data) do
				if k == val then 
					ret = ret + v
				end
			end
		end
	end
	return ret
end

--- itemGetEquipmentArmor
--- returns equipment armor added up from all equipped items.
function itemGetEquipmentArmor()
	local arm = 0
	for k, v in pairs(itemsEquipment) do
		if v and v.data.armor then
			arm = arm + v.data.armor 
		end
	end
	return arm
end

--- itemSortInventory
--- sorts player inventory in order of itemsInventorySort.
function itemSortInventory()
	local itms = { }
	local sortTypeExist = false
	--- First sort items by sort type
	for i = 1, # itemsInventorySort do
	
		--- pick out sort type items
		local start = # itms + 1
		sortTypeExist = false
		for j = # itemsInventory, 1, -1 do
			if itemsInventory[j].data.sort == itemsInventorySort[i] then
				table.insert(itms, itemsInventory[j])
				sortTypeExist = true
			end
		end

		--- go through sort type items and resort by alphabet
		if sortTypeExist then
			for j = start, # itms do
				for k = j, # itms do
					if itms[k] and itms[j] then
					
						local sortName1 = itms[k].data.name
						local sortName2 = itms[j].data.name
						local s = 1
						if itms[k].data.idname then sortName1 = itms[k].data.idname end
						if itms[j].data.idname then sortName2 = itms[j].data.idname end
						
						if sortName1 ~= sortName2 and string.byte(sortName1, 1) == string.byte(sortName2, 1) then
							while string.byte(sortName1, s) == string.byte(sortName2, s) do
								s = s + 1
							end
						end

						if string.byte(sortName1, s) < string.byte(sortName2, s) then
							local temp = itms[j]
							itms[j] = itms[k]
							itms[k] = temp
						end
					
					end
				end
			end
		end
	end
	itemsInventory = { }
	itemsInventory = itms
end

--- itemIsIdentified
--- checks if a passed item has been identified or not. returns true if so, else false.
function itemIsIdentified(item)
	for i = 1, # itemsIdentified do
		if itemsIdentified[i] == item.data.idname then
			return true
		end
	end
	return false
end

--- itemIsIdentified
--- Checks if a passed item has been identified or not.
--- Return true if identified, false if not.
function itemIsIdentified(item)
	if not item.data.idname then return true end
	for i = 1, # itemsIdentified do
		if itemsIdentified[i] == item.data.idname then
			return true
		end
	end
	return false
end

--- itemIsInInventory
--- Searches if an item by the passed name is in the inventory.
--- Returns true if so, else returns false.
function itemIsInInventory(item)
	for i = 1, # itemsInventory do
		if itemsInventory[i].data.name == item then
			return true
		end
	end
	return false
end

--- itemRemoveFromInventory
--- Searches for and removes an item by the passed name from the
--- players inventory. 
function itemRemoveFromInventory(item)
	for i = 1, # itemsInventory do
		if itemsInventory[i].data.name == item then
			table.remove(itemsInventory, i)
			break
		end
	end
end

--- itemAddIdentify
--- adds an item to the identified list if its not already there. 
function itemAddIdentify(item)
	if not item.data.idname then return true end
	if not itemIsIdentified(item) then
		messageRecieve("You've identified this " .. item.data.name .. " as " .. item.data.singular .. item.data.idname .. ".")
		table.insert(itemsIdentified, item.data.idname)
		return false
	end
	return true
end

--- itemGetItemAt
--- Returns an item if it exists in the game world at the passed coordinates
function itemGetItemAt(x, y)
	local i = false 
	for k = 1, # items do
		if items[k].x == x and items[k].y == y then
			return items[k].data
		end
	end
	return false
end

--- itemGetName
--- returns the name of an item that the player is supposed to see.
function itemGetName(item)
	if item.data.idname and itemIsIdentified(item) then
		return item.data.idname
	else
		return item.data.name
	end
	return "foobar"
end

--- Getters
--- itemGetInventoryOpen
function itemGetInventoryOpen() return itemsInventoryOpen end