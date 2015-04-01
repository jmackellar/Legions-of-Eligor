--- Main.lua
--- Main program loop.  Handles game states and the
--- simulated console output.

--- Dependent Files
require "console"
require "debugtools"

--- libraries
Ser = require "ser"

--- Game State Files
require "newgame"
require "game"

local gameState = 'newgame'

--- debugFlags
debugQuickKill = true

--- control
local mainDisableSave = false

function love.load()
	love.window.setTitle("Legions of Eligor")
	math.randomseed(os.time())
	consoleInit(80, 26, 10, 16)
	gameState = 'newgame'			--- Set state to newgame
	gameStateChangeState(gameState) --- Sets gamestate to start
	love.keyboard.setKeyRepeat(true)
end

function love.update(dt)
	--- Need to call each game state update function
	if gameState == 'newgame' then newgameUpdate(dt) end
	if gameState == 'game' then gameUpdate(dt) end
end

function love.keypressed(key)
	--- Need to call each game state keypressed function
	if gameState == 'newgame' then newgameKeypressed(key) end
	if gameState == 'game' then gameKeypressed(key) end
	--- Debugtools
	debugtoolsKeypressed(key)
	--- Quick Kill
	if key == 'escape' and debugQuickKill then
		love.event.push('quit')
	end
end

function love.draw()
	--- Draw simulated console window
	consoleDraw()
	--- Debugtools
	debugtoolsDraw()
end

function gameStateChangeState(state)
	gameState = state
	--- Need to check for each game state
	if gameState == 'newgame' then newgameEnter() end
	if gameState == 'game' then gameEnter() end
end

function mainDisableSaves()
	mainDisableSave = true
end