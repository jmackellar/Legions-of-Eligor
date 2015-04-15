--- Newgame.lua
--- Newgame game state file.  Creating a character.

require "data/class"

local font = love.graphics.newFont("font.ttf", 16)
love.graphics.setFont(font)

local menu = { 'New Game', 'Load Game', 'Exit Game', }
local menuX = 36
local menuY = 17
local cursor = 1
local classSelect = false
local class = false

local menuImage = love.graphics.newImage("menu.png"):getData()

function newgameEnter()
	consoleFlush()
	
	--- create menu image
	for x = 0, 79 do
		for y = 0, 25 do
			local r, g, b, a = menuImage:getPixel(x, y)
			print(r, g, b, a)
			consolePut({char = ' ', backColor = {r, g, b, a}, x = x + 1, y = y + 1})
		end
	end
	
	if love.filesystem.exists("playersave.lua") then
		cursor = 2
	end
end

function newgameUpdate(dt)
	newgameDraw()
end

function newgameDraw()
	if not classSelect then
		for i = 1, # menu do
			if cursor == i then
				consolePrint({string = menu[i], x = menuX, y = menuY + i - 1, backColor = {255, 255, 255, 255}, textColor = {0, 0, 0, 255}})
			else
				consolePrint({string = menu[i], x = menuX, y = menuY + i - 1, backColor = {0, 0, 0, 255}, textColor = {255, 255, 255, 255}})
			end
		end
	else
		consolePrint({string = 'Choose your class', x = menuX - 4, y = menuY - 3})
		if cursor == 1 then
			consolePrint({string = 'Vagrant', x = menuX, y = menuY, backColor = {255, 255, 255, 255}, textColor = {0, 0, 0, 255}})
			consolePrint({string = 'Arcanist', x = menuX, y = menuY + 1})
		elseif cursor == 2 then
			consolePrint({string = 'Vagrant', x = menuX, y = menuY})
			consolePrint({string = 'Arcanist', x = menuX, y = menuY + 1, backColor = {255, 255, 255, 255}, textColor = {0, 0, 0, 255}})
		end
	end
end

function newgameKeypressed(key)
	if not classSelect then
		if key == 'up' or key == 'kp8' then
			cursor = cursor - 1
			if cursor < 1 then cursor = 1 end
		elseif key == 'down' or key == 'kp2' then
			cursor = cursor + 1
			if cursor > # menu then cursor = # menu end
		elseif key == 'return' then
			if cursor == 1 then
				classSelect = true
				consoleFlush()
			elseif cursor == 2 then
				gameStateChangeState('game')
			elseif cursor == 3 then
				love.event.push('quit')
			end
		end
	else
		if key == 'up' or key == 'kp8' then
			cursor = cursor - 1
			if cursor < 1 then cursor = 1 end
		elseif key == 'down' or key == 'kp2' then
			cursor = cursor + 1
			if cursor > 2 then cursor = 2 end
		end
		if key == 'return' then
			if cursor == 1 then
				class = 'Vagrant'
			else
				class = 'Arcanist'
			end
			local files = love.filesystem.getDirectoryItems("")
			for i = 1, # files do
				love.filesystem.remove(files[i])
			end
			gameStateChangeState('game')
		end
	end
end

function newgameGetClass() return class end