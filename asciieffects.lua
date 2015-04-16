--- asciieffect
--- Graphical effects such as partciles, projectiles, or explosions

local effects = { }

function aeInit()
	effects = { }
end

--- aeUpdateEffects
--- Updates all current ascii effects
function aeUpdateEffects(dt)
	if # effects == 0 then return end
	
	--- Only update the top most effect at a time.
	local fx = effects[1]
	if # fx > 0 then
		--- Update the top graphic of the current effect table
		local gfx = fx[1]
		gfx[1].dt = gfx[1].dt - dt
		if gfx[1].dt <= 0 then
			table.remove(fx, 1)
		end
	else
		table.remove(effects, 1)
	end
end

--- aeDrawEffects
--- Draws all current ascii effects
function aeDrawEffects()
	if # effects == 0 or # effects[1] == 0 then return end
	
	--- Only draw the top most effect at a time
	local fx = effects[1]
	local gfx = fx[1]
	
	for k, v in pairs(gfx) do
		consolePut({char = v.char, textColor = v.textColor, backColor = v.backColor, x = v.x, y = v.y + 1})
	end
	gameSetRedrawMap()
	gameSetRedrawItem()
end

--- aeExplosion
--- Creates and adds an explosion gfx
function aeExplosion(x, y, radius, tC, bC)
	local tC = tC or {255, 255, 255, 255}
	local bC = bC or {0, 0, 0, 255}
	local ae = { }
	table.insert(ae, {x = x - radius, y = y - radius, char = '/', textColor = tC, backColor = bC, dt = 0.07})
	table.insert(ae, {x = x + radius, y = y - radius, char = '\\', textColor = tC, backColor = bC, dt = 0.07})
	table.insert(ae, {x = x - radius, y = y + radius, char = '\\', textColor = tC, backColor = bC, dt = 0.07})
	table.insert(ae, {x = x + radius, y = y + radius, char = '/', textColor = tC, backColor = bC, dt = 0.07})
	for xx = x - radius + 1, x + radius - 1 do
		table.insert(ae, {x = xx, y = y - radius, char = '-', textColor = tC, backColor = bC, dt = 0.07})
		table.insert(ae, {x = xx, y = y + radius, char = '-', textColor = tC, backColor = bC, dt = 0.07})
	end
	for yy = y - radius + 1, y + radius - 1 do
		table.insert(ae, {x = x - radius, y = yy, char = '|', textColor = tC, backColor = bC, dt = 0.07})
		table.insert(ae, {x = x + radius, y = yy, char = '|', textColor = tC, backColor = bC, dt = 0.07})
	end
	for xx = x - radius + 1, x + radius - 1 do
		for yy = y - radius + 1, y + radius - 1 do
			table.insert(ae, { x = xx, y = yy, char = ' ', textColor = tC, backColor = bC, dt = 0.07})
		end
	end
	aeAddEffect({ae})
end

--- aeProjectile
--- Creates and adds a projectile gfx
function aeProjectile(sx, sy, dx, dy, dist, ch, tC, bC)
	local ch = ch or '*'
	local tC = tC or {255, 255, 255, 255}
	local bC = bC or {0, 0, 0, 255}
	local ae = { }
	for i = 1, dist do
		ae = { }
		table.insert(ae, {x = sx, y = sy, char = ch, textColor = tC, backColor = bC, dt = 0.05})
		sx = sx + dx
		sy = sy + dy
		aeAddEffect({ae})
	end
end

--- aeAddEffect
function aeAddEffect(fx)
	table.insert(effects, fx)
end

--- aeHasEffects
--- Returns true if there are currently effects being processed 
function aeHasEffects()
	if # effects > 0 then
		return true
	else
		return false
	end
end