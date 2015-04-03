--- message.lua
--- In game message system.  recieves and displays messages to
--- the player.

local messages = { }
local messagesUnread = { }
local messagesMax = 20

local messageRestrictKeypress = false
local acceptMessages = true

function messageInit(mx)
	messagesMax = mx
	messages = { }
	messagesUnread = { }
	table.insert(messagesUnread, "Welcome.")
end

--- fuck i think i spelled this shit wrong -_-
function messageRecieve(msg)
	if not acceptMessages then return end
	if msg == 'Game Over' then 
		acceptMessages = false
	end
	table.insert(messagesUnread, msg)
	if # messagesUnread > 1 then
		if string.len(messagesUnread[#messagesUnread-1] .. "  " .. messagesUnread[#messagesUnread]) <= 72 then
			messagesUnread[#messagesUnread-1] = messagesUnread[#messagesUnread-1] .. "  " .. messagesUnread[#messagesUnread]
			table.remove(messagesUnread)
		end
	end
end

function messageDraw()
	consolePrint({string = "                                                                                ", x = 1, y = 1})
	if # messagesUnread == 0 then
		consolePrint({string = messages[#messages], x = 1, y = 1})
	elseif # messagesUnread > 1 then
		consolePrint({string = messagesUnread[1] .. " [more]", x = 1, y = 1})
	elseif # messageUnread == 1 then
		consolePrint({string = messagesUnread[1], x = 1, y = 1})
	end
end

function messageUpdate(dt)
	while # messages > messagesMax do
		table.remove(messages, 1)
	end
	if # messagesUnread == 1 then
		table.insert(messages, messagesUnread[1])
		table.remove(messagesUnread, 1)
		messageRestrictKeypress = false
	elseif # messagesUnread > 1 then
		messageRestrictKeypress = true
	elseif # messagesUnread == 0 then
		messageRestrictKeypress = false
	end
end

function messageKeypressed(key)
	if # messagesUnread > 1 then
		if key then
			table.insert(messages, messagesUnread[1])
			table.remove(messagesUnread, 1)
		end
	end
end

--- messageGetMsgList
--- Returns a formatted list of all recently recieved messages.
function messageGetMsgList()
	local msg = ""
	print("---------------START-------------------")
	for i = 1, # messages do
		print(messages[i])
		msg = msg .. messages[i] .. "/n"
	end
	print("---------------END---------------------")
	return msg
end

--- Getters
function messageGetRestrictKeypress() return messageRestrictKeypress end
function messageGetMessages() return messages end