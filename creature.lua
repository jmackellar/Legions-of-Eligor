--- creature.lua
--- AI controlled creatures.  Monsters, Allies, bosses. 

local creatures = { }

function creatureClearAll()
	creatures = { }
end

function creatureDraw()
	for i = 1, # creatures do
		local c = creatures[i]
		if mapIsLit(c.x, c.y) or debugDisableFog then
			consolePut({char = c.data.char, textColor = c.data.textColor, backColor = c.data.backColor, x = c.x, y = c.y + 1})
		end
	end
end

--- creatureSave
function creatureSave(prefix)
	local c = prefix .. "creaturesave.lua"
	local cf = love.filesystem.newFile(c)
	love.filesystem.write(c, Ser(creatures))
end

--- creatureLoad
function creatureLoad(prefix)
	local c = prefix .. "creaturesave.lua"
	if love.filesystem.exists(c) then
		local c1 = love.filesystem.load(c)
		creatures = c1()
		return true
	end
	return false
end

function creatureCalcDamage(c)
	local dam = c.data.damage
	local d = 0 + creatureGetModVal(c, 'damage')
	for i = 1, dam.sides do
		d = d + math.random(1, dam.dice)
		d = d + dam.bonus
	end
	return d
end

function creatureTurn()
	gameFlipPlayerTurn()
	for i = # creatures, 1, -1 do
		--- Set creatures speed check to players speed value.
		--- If creatures speed check is greater than or equal to their
		--- speed value then they take turns until the speed value is
		--- greater than the speed check.
		creatures[i].speed = (creatures[i].speed + creatureGetModVal(creatures[i], 'speed') ) + playerGetSpeed()
		--- Tick down modifiers every turn
		creatureTickMod(creatures[i])
		while creatures[i].speed >= creatures[i].data.speed do
			if creatures[i].seen then
				--- Creature AI 
				
				--- If the creature has been seen and is out of range of the
				--- player for a set time then revert seen to false.
				if not mapFog[creatures[i].x][creatures[i].y].lit then
					creatures[i].lastseen = creatures[i].lastseen + 1
					if creatures[i].lastseen >= 15 then
						creatures[i].seen = false
						creatures[i].lastseen = 0
					end
				end
				
				--- Modifiers may change what AI the creature is using
				--- for a few turns.  If the creature doesn't have any
				--- AI modifiers then use the default AI for that creature
				--- instead.
				local ai = creatureGetModVal(creatures[i], 'ai')
				if ai == 1 then 
					ai = 'grunt'
				elseif ai == 0 then
					ai = creatures[i].data.ai
				end
				
				--- Take turn passed on current AI state
				if ai == 'grunt' then
					creatureGrunt(creatures[i])
				elseif ai == 'ranged' then
					creatureRanged(creatures[i])
				elseif ai == 'scared' then
					creatureScared(creatures[i])
				end
			else
				creatures[i].lastseen = 0
				creatureWander(creatures[i])
			end
			--- Subtract speed check by speed value
			creatures[i].speed = creatures[i].speed - creatures[i].data.speed
		end
	end
end

function creatureAttackedByPlayer(x, y, dam, msg3)
	local msg = ""
	for i = 1, # creatures do
		if creatures[i].x == x and creatures[i].y == y then
			local armor = (creatures[i].data.armor + creatureGetModVal(creatures[i], 'armor'))
			local d = dam
			for i = 1, armor do
				d = d - math.random(0, 1)
				d = math.max(1, d)
			end
			creatures[i].health = creatures[i].health - d
			if msg3 then
				msg = msg3
			else
				msg = "You hit " .. creatures[i].data.prefix .. creatures[i].data.name .. "."
			end
			if creatures[i].health < 1 then
				--- Death drops
				if creatures[i].data.deathItem then
					for j = 1, # creatures[i].data.deathItem do
						local item = gameItems[creatures[i].data.deathItem[j]]
						itemPlace(item, creatures[i].x, creatures[i].y)
					end
				end
				--- die
				msg = msg .. "  You killed " .. creatures[i].data.prefix .. creatures[i].data.name .. "."			
				mapDrawTile(x, y)
				playerAddExp(creatures[i].data.xp)
				table.remove(creatures, i)
			end
			messageRecieve(msg)
			return
		end
	end
end

function creatureWander(c)
	local dx = math.random(-1, 1)
	local dy = math.random(-1, 1)
	if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
		c.x = c.x + dx
		c.y = c.y + dy
	elseif not playerIsTileFree(c.x + dx, c.y + dy) then
		playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c))
	end
	if c.data.ai ~= 'wander' then
		if mapIsLit(c.x, c.y) then
			c.seen = true
			c.lastseen = 0
		end
	end
end

--- creatureAddMod(c, s)
--- Adds a mod to nearby creatures of the spells targeted monster name.
--- If target name is 'all' then all monsters get the mod, else only
--- monsters with the name that is targeted get the modifier.
function creatureAddMod(c, s)
	local x1 = math.max(1, c.x - s.range)
	local x2 = math.min(mapGetWidth(), c.x + s.range)
	local y1 = math.max(1, c.y - s.range)
	local y2 = math.min(mapGetHeight(), c.y + s.range)
	local montype = s.monster
	if not s.castmsg then
		if montype == 'all' then
			messageRecieve(c.data.prefix .. c.data.name .. " modifies all nearby monsters.")
		else
			messageRecieve(c.data.prefix .. c.data.name .. " modifies all nearby " .. montype)
		end
	else
		messageRecieve(s.castmsg)
	end
	for xx = x1, x2 do
		for yy = y1, y2 do
			if not creatureIsTileFree(xx, yy) then
				local mon = creatureGetCreatureAtTile(xx, yy)
				if mon.data.name == montype or montype == 'all' then
					creatureAddModAt({mod = s.mod, val = s.val, turn = s.turns}, xx, yy)
				end
			end
		end
	end
end

--- creatureSummon(c, s)
--- Takes passed creature and passed spell and summons nasties around the
--- creature.
function creatureSummon(c, s)
	local x1 = math.max(1, c.x - 3)
	local x2 = math.min(mapGetWidth(), c.x + 3)
	local y1 = math.max(1, c.y - 3)
	local y2 = math.min(mapGetHeight(), c.y + 3)
	local placed = 0
	local attempt = 0
	while placed < s.amnt do
		if attempt >= 50 then break end
		for xx = x1, x2 do
			for yy = y1, y2 do
				--- Summon monster at targeted tile with a chance
				if math.random(1, 100) <= 25 and placed < s.amnt then
					if creatureSpawn(xx, yy, s.monster) then
						placed = placed + 1
					else
						attempt = attempt + 1
					end
				end
			end
		end
	end
	messageRecieve(c.data.prefix .. c.data.name .. " summons other creatures.")
end

--- creatureMapEffectSpell(c)
--- Takes a passed spell that adds effects to the map.
function creatureMapEffectSpell(c, s)
	--- First find the right target.
	local x = c.x
	local y = c.y
	if s.target == 'player' then
		x = playerGetX()
		y = playerGetY()
	end
	
	--- Next add effect to the map based on spell shape centered 
	--- around the target.
	if s.shape == 'square' then
		---		.....
		---		.XXX.
		---		.XCX.
		---		.XXX.
		---		.....
		local sx = x - math.floor(s.size / 2)
		local sy = y - math.floor(s.size / 2)
		for xx = sx, sx + s.size do
			for yy = sy, sy + s.size do
				mapAddTileEffect(xx, yy, s.effect)
			end
		end
	end
	
	--- Now print the spell casting message.
	gameSetRedrawAll()
	messageRecieve(c.data.prefix .. c.data.name .. " " .. s.effect.castmsg)
end

--- creatureCastSpell(c)
--- Takes a creature and attempts to cast any spells.  Will not cast spells
--- that don't make sense in certain situations, and will not cast spells that
--- are on cool down.  Returns true if a spell was succesfully cast, false if
--- no spell was cast.
function creatureCastSpell(c)
	if not c.data.spells then return false end
	for i = 1, # c.data.spells do
		--- Initialize cd if it doesn't already exist
		if not c.data.spells[i].cd then
			c.data.spells[i]['cd'] = 0
		end
		--- Tick down cooldown.  If cooldown is reset then cast the spell if possible
		c.data.spells[i].cd = c.data.spells[i].cd - 1
		if c.data.spells[i].cd <= 0 then
			--- Summoning
			if c.data.spells[i].name == 'summon' then
				creatureSummon(c, c.data.spells[i])
				c.data.spells[i].cd = c.data.spells[i].cooldown
				return true
			--- Modify nearby monsters
			elseif c.data.spells[i].name == 'addmod' then
				creatureAddMod(c, c.data.spells[i])
				c.data.spells[i].cd = c.data.spells[i].cooldown
				return true
			--- Add tile effects
			elseif c.data.spells[i].name == 'mapeffect' then
				creatureMapEffectSpell(c, c.data.spells[i])
				c.data.spells[i].cd = c.data.spells[i].cooldown
				return true
			end
		end
	end
	return false
end

--- Takes a creatures ranged attack properties and tries to shoot the player.
--- returns true if the creature fired, false if the creature was not able
--- to shoot the player.
function creatureShootPlayer(c)
	local move = {{0, -1}, {1, -1}, {1, 0}, {1, 1}, {0, 1}, {-1, 1}, {-1, 0}, {-1, -1}}
	local moving = {true, true, true, true, true, true, true, true}
	local sx = c.x
	local sy = c.y
	local dam = 0
	--- Check if the creature has a ranged attack first.
	if c.data.ranged then
		--- Calculate damage of the shot before firing.
		for i = 1, c.data.ranged.dice do
			dam = dam + math.random(1, c.data.ranged.sides)
			dam = dam + c.data.ranged.bonus
		end
		--- Fire a shot. If it hits the player then do damage and print a message.
		--- Else return false and pretend like the creature never even fired.
		for i = 1, c.data.ranged.range do
			for j = 1, # move do
				if moving[j] then
					--- The 'fake' shot hit the player and now becomes a real shot and returns true.
					--- Damage the player and display message first.
					if not playerIsTileFree(sx + (move[j][1] * (i-1)), sy + (move[j][2] * (i-1))) then
						moving[j] = false
						playerRecieveDamage(dam)
						messageRecieve(c.data.ranged.msg)
						return true
					--- The 'fake' shot runs into a wall.  Terminate the shot and no longer
					--- update it.
					elseif not mapGetWalkThru(sx + (move[j][1] * (i-1)), sy + (move[j][2] * (i-1))) then
						moving[j] = false
					end
				end
			end
		end
	end
	return false
end

--- creatureScared
--- Scared AI
--- Attempts to keep a set distance from the player, however
--- if the player gets close to the creature the creature will
--- instead attack.  The creature will attempt to run away if
--- it's health nears 0.
function creatureScared(c)
	local dx = 0
	local dy = 0
	local dist = math.sqrt( (c.x - playerGetX())^2 + (c.y - playerGetY())^2 )
	local move = false
	--- Attempt to stay more than three tiles away from the player.
	--- If creature health is less than 6 then also run away from the player.
	if (dist <= 5 and dist > 2) or c.data.health <= 5 then
		--- Creature needs to run away.
		if not move then
			if playerGetX() > c.x then dx = -1 end
			if playerGetX() < c.x then dx = 1 end
			if playerGetY() > c.y then dy = -1 end
			if playerGetY() < c.y then dy = 1 end
			move = true
		end
	--- If creature is next to the player then attack instead
	elseif dist <= 2 then
		if not move then
			if playerGetX() > c.x then dx = 1 end
			if playerGetX() < c.x then dx = -1 end
			if playerGetY() > c.y then dy = 1 end
			if playerGetY() < c.y then dy = -1 end
			move = true
		end
	end
	--- Have the creature try to cast a spell. If it cant cast anything 
	--- then move instead.
	if not creatureCastSpell(c) then
		if move then
			--- Targeted tile is free so move towards it.
			if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
				c.x = c.x + dx
				c.y = c.y + dy
			--- Player is on targeted tile.  Attack!
			elseif not playerIsTileFree(c.x + dx, c.y + dy) then
				playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c))
			--- Else if we can't move to that tile at all pick a new one and try again.
			else
				move = false
			end
		end
		--- Creature didn't move, time to do random movement that
		--- makes zero sense whatsoever.
		if not move then
			local tries = 0
			while not move and tries <= 8 do
				tries = tries + 1
				dx = math.random(-1, 1)
				dy = math.random(-1, 1)
				if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
					move = true
					c.x = c.x + dx
					c.y = c.y + dy
				end
			end
		end
	end
end

--- creatureRanged
--- Ranged AI
--- moves away from the player if close.  If distance from
--- player is far enough shoot the player if in shooting sight.
--- Else move laterally to line the player up.
function creatureRanged(c)
	local dx = 0
	local dy = 0
	local dist = math.sqrt( (c.x - playerGetX())^2 + (c.y - playerGetY())^2 )
	local r = c.data.ranged.range or 0
	--- If distance is closer than 4 tiles then run away
	if dist <= 4 then
		if playerGetX() > c.x then dx = -1 end
		if playerGetX() < c.x then dx = 1 end
		if playerGetY() > c.y then dy = -1 end
		if playerGetY() < c.y then dy = 1 end
		--- move away from player now.
		if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
			c.x = c.x + dx
			c.y = c.y + dy
		--- That tile was not available, time to move randomly!
		else
			dx = math.random(-1, 1)
			dy = math.random(-1, 1)
			--- Random movement
			if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
				c.x = c.x + dx
				c.y = c.y + dy
			end
		end
	--- If their is distance between the player and the creature
	--- has enough range to hit the player then shoot or cast a spell.  
	--- Else the creature needs to move closer.
	elseif dist < r then
		if not creatureShootPlayer(c) then
			if not creatureCastSpell(c) then
				--- Player was not in creatures line of fire.  Move randomly now.
				dx = math.random(-1, 1)
				dy = math.random(-1, 1)
				--- Random movement
				if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
					c.x = c.x + dx
					c.y = c.y + dy
				end
			end
		end
	--- Move towards the player.  Attack the player if the creature
	--- runs into the player.
	else
		if playerGetX() > c.x then dx = 1 end
		if playerGetX() < c.x then dx = -1 end
		if playerGetY() > c.y then dy = 1 end
		if playerGetY() < c.y then dy = -1 end
		if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
			c.x = c.x + dx
			c.y = c.y + dy
		elseif not playerIsTileFree(c.x + dx, c.y + dy) then
			playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c))
		end
	end
end

--- creatureTickMod
--- Ticks mods down and removes when time is out.
function creatureTickMod(c)
	if not c.mod then return end
	for i = # c.mod, 1, -1 do
		c.mod[i].turn = c.mod[i].turn - 1
		if c.mod[i].turn <= 0 then
			table.remove(c.mod, i)
		end
	end
end

--- creatureAddModAt
--- Adds a passed modifier to any creature that is on the targeted tile.
function creatureAddModAt(mod, x, y)
	for i = 1, # creatures do
		if creatures[i].x == x and creatures[i].y == y then
			table.insert(creatures[i].mod, mod)
		end
	end
end

--- creatureGetModVal
--- Returns the value of a modifier for the passed key.
function creatureGetModVal(creature, key)
	local val = 0
	if not creature.mod then return val end
	for i = 1, # creature.mod do
		if creature.mod[i].mod == key then
			val = val + creature.mod[i].val
		end
	end
	return val
end

--- creatureGrunt
--- Grunt AI
--- moves towards the player.  Melees the player.  If a grunt has a ranged attack
--- it will try to use it against the player when at a distance.
function creatureGrunt(c)
	local dx = 0
	local dy = 0
	if playerGetX() > c.x then dx = 1 end
	if playerGetX() < c.x then dx = -1 end
	if playerGetY() > c.y then dy = 1 end
	if playerGetY() < c.y then dy = -1 end
	--- Attempt to cast a spell.  If not then move
	if not creatureCastSpell(c) then
		if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
			if math.random(1, 100) <= 50 then
				--- Attempt to shoot the player.  If the creature doesn't have a ranged attack
				--- then the function will return false and the creature will move instead.  The
				--- function will also return false if the player isn't in the creature's line of 
				--- fire.
				if not creatureShootPlayer(c) then
					c.x = c.x + dx
					c.y = c.y + dy
				end
			else
				c.x = c.x + dx
				c.y = c.y + dy
			end
		elseif not playerIsTileFree(c.x + dx, c.y + dy) then
			playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c))
		end
	end
end

function creatureSpawn(x, y, name)
	if gameMonsters[name] and x > 0 and y > 0 and x <= mapGetWidth() and y <= mapGetHeight() and mapGetWalkThru(x, y) then
		if creatureIsTileFree(x, y) and playerIsTileFree(x, y) then
			table.insert(creatures, {data = gameMonsters[name], lastseen = 0, health = gameMonsters[name].health, x = x, y = y, speed = 0, seen = false, mod = { }})
			gameSetRedrawCreature()
			return true
		end
	end
	return false
end

function creatureGetCreatureAtTile(x, y)
	for i = 1, # creatures do
		if creatures[i].x == x and creatures[i].y == y then
			return creatures[i]
		end
	end
	return false
end

function creatureIsTileFree(x, y)
	for i = 1, # creatures do
		if creatures[i].x == x and creatures[i].y == y then
			return false
		end
	end
	return true
end