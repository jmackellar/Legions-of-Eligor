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

function creatureCalcDamage(dam)
	local d = 0
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
		creatures[i].speed = creatures[i].speed + playerGetSpeed()
		while creatures[i].speed >= creatures[i].data.speed do
			if creatures[i].seen then
				--- Creature AI states
				if creatures[i].data.ai == 'grunt' then
					creatureGrunt(creatures[i])
				elseif creatures[i].data.ai == 'ranged' then
					creatureRanged(creatures[i])
				elseif creatures[i].data.ai == 'scared' then
					creatureScared(creatures[i])
				end
			else
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
		playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c.data.damage))
	end
	if c.data.ai ~= 'wander' then
		if mapIsLit(c.x, c.y) then
			c.seen = true
		end
	end
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
	print(dist)
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
	--- Now move the creature.
	if move then
		--- Targeted tile is free so move towards it.
		if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
			c.x = c.x + dx
			c.y = c.y + dy
		--- Player is on targeted tile.  Attack!
		elseif not playerIsTileFree(c.x + dx, c.y + dy) then
			playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c.data.damage))
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
	--- has enough range to hit the player then shoot.  Else the 
	--- creature needs to move closer.
	elseif dist < r then
		if not creatureShootPlayer(c) then
			--- Player was not in creatures line of fire.  Move randomly now.
			dx = math.random(-1, 1)
			dy = math.random(-1, 1)
			--- Random movement
			if mapGetWalkThru(c.x + dx, c.y + dy) and creatureIsTileFree(c.x + dx, c.y + dy) and playerIsTileFree(c.x + dx, c.y + dy) then
				c.x = c.x + dx
				c.y = c.y + dy
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
			playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c.data.damage))
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
		playerAttackedByCreature(c.data.name, c.data.prefix, creatureCalcDamage(c.data.damage))
	end
end

function creatureSpawn(x, y, name)
	if gameMonsters[name] and x > 0 and y > 0 and x <= mapGetWidth() and y <= mapGetHeight() and mapGetWalkThru(x, y) then
		if creatureIsTileFree(x, y) and playerIsTileFree(x, y) then
			table.insert(creatures, {data = gameMonsters[name], health = gameMonsters[name].health, x = x, y = y, speed = 0, seen = false, mod = { }})
			gameSetRedrawCreature()
		end
	end
end

function creatureIsTileFree(x, y)
	for i = 1, # creatures do
		if creatures[i].x == x and creatures[i].y == y then
			return false
		end
	end
	return true
end