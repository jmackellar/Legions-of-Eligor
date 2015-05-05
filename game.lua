--- Game.lua
--- Main game loop.  

--- data files
require "data/messages"
require "data/tiles"
require "data/branch"
require "data/monster"
require "data/items"
require "data/class"
require "data/magicitems"

--- dependencies
require "map"
require "player"
require "creature"
require "item"
require "message"
require "asciieffects"

local redrawMap = true
local redrawPlayer = true
local redrawCreature = true
local redrawItem = true

local playerTurn = true

function gameEnter()
	mapInit(80, 21)
	--name, level, health, mana, vit, ment, endur, will, perStat, perAmnt, class
	playerInit("Jesse", 1, 100, 100, 5, 5, 5, 5, newgameGetClass())
	playerLoad()
	if not mapLoad() then
		mapGenTown(mapGetWidth(), mapGetHeight()) 
	end
	messageInit(26)
	aeInit()
	mapGenWanderDijkstras(3)
	redrawMap = true
	redrawPlayer = true
end

function gameClearSave()
	local s = love.filesystem.getDirectoryItems("")
	for i = 1, # s do
		love.filesystem.remove(s[i])
	end
end

function gameUpdate(dt)

	aeUpdateEffects(dt)
	creatureUpdate(dt)
	playerUpdate(dt)

	--- if not playerTurn, then creatures take turn
	if not playerTurn and not aeHasEffects() then
		creatureTurn()
		gameSetRedrawAll()
	end

	if redrawMap then
		mapDraw()
		redrawMap = false
	end
	if redrawItem then
		itemDraw()
		redrawItem = false
	end
	
	mapDrawEffects()

	if redrawPlayer then
		playerDraw()
		redrawPlayer = false
	end
	if redrawCreature then
		creatureDraw()
		redrawCreature = false
	end
	
	aeDrawEffects()
	
	playerDrawHud()
	--- inventory menu
	if itemGetInventoryOpen() then
		itemDrawInventory()
	end
	messageUpdate(dt)
	messageDraw()
	playerDrawMenu()
end

function gameKeypressed(key)
	if not aeHasEffects() then
		if playerGetHealth() > 0 then
			if itemKeypressed(key) then return end
			if not messageGetRestrictKeypress() then
				if debugGetMenuOpen() then return end
				if playerTurn then
					if playerKeypressed(key) then return end
				end
			end
			messageKeypressed(key)
		else
			messageKeypressed(key)
		end
	end
end

--- gameSave
--- saves the entire game.
function gameSave()
	playerSave()
	mapSave()
end

--- gameSetRedrawAll
--- Sets the game to redraw everything.
function gameSetRedrawAll()
	redrawMap = true
	redrawPlayer = true
	redrawCreature = true
	redrawItem = true
end

--- gameSetRedrawItem
--- sets redrawItem to true.
function gameSetRedrawItem()
	redrawItem = true
end

--- gameSetRedrawMap
--- Sets redrawMap to true.
function gameSetRedrawMap()
	redrawMap = true
end

--- gameSetRedrawPlayer
--- Sets redrawPlayer to true
function gameSetRedrawPlayer()
	redrawPlayer = true
end

--- gameSetRedrawCreature
--- Sets redrawCreature to true
function gameSetRedrawCreature()
	redrawCreature = true
end

--- gameFlipPlayerTurn
--- Flips playerTurn between true and false.
function gameFlipPlayerTurn()
	if playerTurn then
		playerTurn = false
		playerIncTurns()
		playerRegenTurn()
		playerModifierUpdate()
		mapUpdateTileEffect()
		mapCreatureSpawn()
	else
		playerTurn = true
	end
end