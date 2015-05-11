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
		consoleFlush()
		consolePrint({string = 'Choose Your', x = menuX - 33, y = menuY - 15})
		consolePrint({string = '   Class', x = menuX - 33, y = menuY - 14})
		local msg = true
		for y = 1, consoleGetWindowHeight() do
			consolePut({char = '|', x = 16, y = y, textColor = {222, 207, 120, 255}})
		end
		consolePrint({string = "---------------+", x = 1, y = 5, textColor = {222, 207, 120, 255}})
		if cursor == 1 then
			consolePrint({string = 'Vagrant', x = menuX - 33, y = menuY - 10, backColor = {255, 255, 255, 255}, textColor = {0, 0, 0, 255}})
			consolePrint({string = 'Arcanist', x = menuX - 33, y = menuY - 10 + 1})
			msg = gameMessages.vagrantIntro
		elseif cursor == 2 then
			consolePrint({string = 'Vagrant', x = menuX - 33, y = menuY - 10})
			consolePrint({string = 'Arcanist', x = menuX - 33, y = menuY - 10 + 1, backColor = {255, 255, 255, 255}, textColor = {0, 0, 0, 255}})
			msg = gameMessages.arcanistIntro
		end

		--- Class description
		for i = 1, # msg do
			consolePrint({string = msg[i], x = menuX - 16, y = menuY - 13 + i})
		end

		--- Class stats
		local table = {"Vagrant", "Arcanist"}
		local class = gameClasses[table[cursor]]
		consolePrint({string = 'Starting Attributes', x = 20, y = 15, textColor = {222, 207, 120, 255}})
		consolePrint({string = 'Vitality :', x = 22, y = 17, textColor = {224, 119, 119, 255}})
		consolePrint({string = 'Endurance:', x = 22, y = 18, textColor = {119, 224, 119, 255}})
		consolePrint({string = 'Mentality:', x = 22, y = 19, textColor = {119, 119, 224, 255}})
		consolePrint({string = 'Willpower:', x = 22, y = 20, textColor = {213, 115, 240, 255}})
		consolePrint({string = class.vit, x = 33, y = 17})
		consolePrint({string = class.endur, x = 33, y = 18})
		consolePrint({string = class.ment, x = 33, y = 19})
		consolePrint({string = class.will, x = 33, y = 20})

		--- Class spells
		consolePrint({string = 'Class Spells', x = 55, y = 15, textColor = {222, 207, 120, 255}})
		for i = 1, # class.spells do
			consolePrint({string = class.spells[i].name, x = 57, y = 16 + i})
		end
	end
end

function newgameKeypressed(key)
	if not classSelect then
		if key == 'up' or key == 'kp8' or key == 'k' then
			cursor = cursor - 1
			if cursor < 1 then cursor = 1 end
		elseif key == 'down' or key == 'kp2' or key == 'j' then
			cursor = cursor + 1
			if cursor > # menu then cursor = # menu end
		elseif key == 'return' then
			if cursor == 1 then
				classSelect = true
				consoleFlush()
			elseif cursor == 2 then
				class = 'Vagrant'
				gameStateChangeState('game')
			elseif cursor == 3 then
				love.event.push('quit')
			end
		end
	else
		if key == 'up' or key == 'kp8' or key == 'k' then
			cursor = cursor - 1
			if cursor < 1 then cursor = 1 end
		elseif key == 'down' or key == 'kp2' or key == 'j' then
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