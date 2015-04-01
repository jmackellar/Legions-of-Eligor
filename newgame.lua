--- Newgame.lua
--- Newgame game state file.  Creating a character.

require "data/class"

local font = love.graphics.newFont("font.ttf", 16)
love.graphics.setFont(font)

local menu = { 'New Game', 'Load Game' }
local menuX = 5
local menuY = 15
local cursor = 1

function newgameEnter()
	consoleFlush()
	if love.filesystem.exists("playersave.lua") then
		cursor = 2
	end
end

function newgameUpdate(dt)
	newgameDraw()
end

function newgameDraw()
	for i = 1, # menu do
		if cursor == i then
			consolePrint({string = menu[i], x = menuX, y = menuY + i - 1, backColor = {255, 255, 255, 255}, textColor = {0, 0, 0, 255}})
		else
			consolePrint({string = menu[i], x = menuX, y = menuY + i - 1, backColor = {0, 0, 0, 255}, textColor = {255, 255, 255, 255}})
		end
	end
end

function newgameKeypressed(key)
	if key == 'up' or key == 'kp8' then
		cursor = cursor - 1
		if cursor < 1 then cursor = 1 end
	elseif key == 'down' or key == 'kp2' then
		cursor = cursor + 1
		if cursor > # menu then cursor = # menu end
	elseif key == 'return' then
		if cursor == 1 then
			local files = love.filesystem.getDirectoryItems("")
			for i = 1, # files do
				love.filesystem.remove(files[i])
			end
			gameStateChangeState('game')
		elseif cursor == 2 then
			gameStateChangeState('game')
		end
	end
end