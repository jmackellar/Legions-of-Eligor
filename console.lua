--- console.lua
--- Simulated console output.  Handles updating and 
--- drawing of characters.

--- TO USE
--- Call consoleInit() in love.load() and consoleDraw() in love.draw()

local window = { }
local windowWidth = 80
local windowHeight = 25
local windowCanvas = nil

local cellWidth = 12
local cellHeight = 12

local redraw = false

--- debugFlags
--- setting this to false will draw a grid around cells.
--- Is a global variable because of how I wrote my game's debugging
--- feature. Change to suit your own needs.
debugDrawCellBorders = false

--- Sets up the console.  Sets cell width and height, and
--- the number of cells per row and column by window width and height respectively. 
--- Calling consoleInit() at any time can be used to resize the game window.
function consoleInit(wW, wH, cW, cH)
	windowWidth = wW
	windowHeight = wH
	cellWidth = cW
	cellHeight = cH
	love.window.setMode(wW * cW, wH * cH)
	windowCanvas = love.graphics.newCanvas(wW * cW, wH * cH)
	window = { }
	for x = 1, wW do
		window[x] = { }
		for y = 1, wH do
			window[x][y] = {char = ' ', textColor = {255, 255, 255, 255}, backColor = {0, 0, 0, 255}}
		end
	end
end

--- consoleDrawCellFront
--- Draws specified cell foreground.
function consoleDrawCellFront(x, y)
	love.graphics.setCanvas(windowCanvas)
	local cell = window[x][y]
	local dx = (x - 1) * cellWidth
	local dy = (y - 1) * cellHeight
	--- text and textColor
	dx = dx + 1
	dy = dy + 0
	love.graphics.setColor(cell.textColor[1], cell.textColor[2], cell.textColor[3], cell.textColor[4])
	love.graphics.print(cell.char, dx, dy)
	--- Set default color
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setCanvas()
end

--- consoleDrawCellBack
--- Draws specified cell background.
function consoleDrawCellBack(x, y)
	love.graphics.setCanvas(windowCanvas)
	local cell = window[x][y]
	local dx = (x - 1) * cellWidth
	local dy = (y - 1) * cellHeight
	--- debugDrawCellBorders
	if debugDrawCellBorders then
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle('line', dx, dy, cellWidth, cellHeight)
	end
	--- backColor
	love.graphics.setColor(cell.backColor[1], cell.backColor[2], cell.backColor[3], cell.backColor[4])
	love.graphics.rectangle('fill', dx, dy, cellWidth, cellHeight)
	love.graphics.setCanvas()
end

--- consoleDrawCellBorder
--- Draws cell borders.  Just a thin white outline around the cell.
function consoleDrawCellBorder(x, y)
	love.graphics.setCanvas(windowCanvas)
	local cell = window[x][y]
	local dx = (x - 1) * cellWidth
	local dy = (y - 1) * cellHeight
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle('line', dx, dy, cellWidth, cellHeight)
	love.graphics.setCanvas()
end

--- consoleDraw
--- Draws console output to off-screen canvas, and then
--- draws canvas onto the main screen.  Off-screen canvas
--- only updates when redraw is set.
function consoleDraw()
	if redraw then
		redraw = false
		--- First loop
		--- Draw cell background color
		for x = 1, windowWidth do
			for y = 1, windowHeight do
				consoleDrawCellBack(x, y)
			end
		end
		--- Second loop
		--- Draw cell character and border if applicable
		for x = 1, windowWidth do
			for y = 1, windowHeight do
				consoleDrawCellFront(x, y)
				if window[x][y].border then
					consoleDrawCellBorder(x, y)
				end
			end
		end	
	end
	love.graphics.draw(windowCanvas)
end

--- consolePrint
--- Prints a string onto the console.
--- args : { x(int), y(int), string(string), textColor({int, int, int, int}), backColor({int, int, int, int}) }
--- Leave any arg blank for default.
function consolePrint(args)
	local s = args.string or 'no-passed-string'
	local tC = args.textColor or {255, 255, 255, 255}
	local bC = args.backColor or {0, 0, 0, 255}
	local x = args.x or 1
	local y = args.y or 1
	local border = args.border or false
	--- Log : console coordinates out of bound
	if x < 1 or x > windowWidth or y < 1 or y > windowHeight then
		print("WARNING console coordinates out of bound.  console.lua, consolePrint")
	end
	for i = 1, string.len(s) do
		local c = string.sub(s, i, i)
		if x+(i-1) <= windowWidth and window[x+(i-1)][y] then
			window[x+(i-1)][y] = {char = c, textColor = tC, backColor = bC, border = border}
		end
	end
	redraw = true
end

--- consolePut
--- Sets cell char, textColor, or backColor.
--- args : { x(int), y(int), char(char), textColor({int, int, int, int}), backColor({int, int, int, int}) }
--- Leave any arg blank for default.
function consolePut(args)
	local c = args.char or ' '
	local tC = args.textColor or {255, 255, 255, 255}
	local bC = args.backColor or {0, 0, 0, 255}
	local x = args.x or 1
	local y = args.y or 1
	local border = args.border or false
	--- Log : console coordinates out of bound.
	if x < 1 or x > windowWidth or y < 1 or y > windowHeight then
		print("WARNING console coordinates out of bound.  console.lua, consolePut")
	end
	window[x][y] = {char = c, textColor = tC, backColor = bC, border = border}
	redraw = true 		--- Set redraw so console window updates with change
end

--- consoleFlushRow
--- Reverts an entire row to default cells.
--- args : row(int)
function consoleFlushRow(row)
	if row > 1 and row < windowHeight + 1 then
		for x = 1, windowWidth do
			window[x][row] = {char = ' ', textColor = {255, 255, 255, 255}, backColor = {0, 0, 0, 255}}
		end
	else
		print("WARNING console row does not exist.  console.lua, consoleFlushRow")
	end
end

--- consoleFlush
--- Flushes all console cells to default.
function consoleFlush()
	for x = 1, windowWidth do
		for y = 1, windowHeight do
			window[x][y] = {char = ' ', textColor = {255, 255, 255, 255}, backColor = {0, 0, 0, 255}}
		end
	end
	redraw = true
end

--- consoleGetCell
--- Gets the character of a cell.
--- args : x(int), y(int)
function consoleGetCell(x, y)
	--- Log : console coordinates out of bound.
	if x < 1 or x > windowWidth or y < 1 or y > windowHeight then
		print("WARNING console coordinates out of bound.  console.lua, consoleGetCell")
		return " "
	else
		return window[x][y].char
	end
end

--- consoleGetCellBackColor
--- Gets the back color of a cell.
--- args : x(int), y(int)
function consoleGetCellBackColor(x, y)
	--- Log : console coordinates out of bound.
	if x < 1 or x > windowWidth or y < 1 or y > windowHeight then
		print("WARNING console coordinates out of bound.  console.lua, consoleGetCellBackColor")
		return {0, 0, 0, 255}
	else
		return window[x][y].backcolor
	end
end

--- consoleGetCellTextColor
--- Gets the text color of a cell.
--- args : x(int), y(int)
function consoleGetCellBackColor(x, y)
	--- Log : console coordinates out of bound.
	if x < 1 or x > windowWidth or y < 1 or y > windowHeight then
		print("WARNING console coordinates out of bound.  console.lua, consoleGetCellTextColor")
		return {0, 0, 0, 255}
	else
		return window[x][y].textcolor
	end
end

--- consoleRedraw
--- Redraws the console output.
function consoleRedraw()
	redraw = true
end

--- consoleSetBorder
--- Sets passed cell to the passed boolean value
function consoleSetBorder(x, y, bool)
	if x >= 1 and y >= 1 and x <= windowWidth and y <= windowHeight then
		window[x][y].border = bool
	end
end

--- consoleGetBorder
--- Returns passed cell's border boolean value.
function consoleGetBorder(x, y)
	if x >= 1 and y >= 1 and x <= windowWidth and y <= windowHeight then
		return window[x][y].border
	end
end

--- Getters
function consoleGetWindowHeight() return windowHeight end
function consoleGetWindowWidth() return windowWidth end
function consoleGetCellHeight() return cellHeight end
function consoleGetCellWidth() return cellWidth end