--shortkeyse for events
local eventKeys = {
	emote = {"CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE"},
	say = {"CHAT_MSG_SAY"},
	yell = {"CHAT_MSG_YELL"},
	public = {"CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_SAY", "CHAT_MSG_YELL"}
}





--Set Slash Command on Load
function chatHighlight_OnLoad()
	SlashCmdList["CHATHIGHTLIGHT"] = chatHightlight_SlashCommandHandler;
	SLASH_CHATHIGHTLIGHT1 = "/chathightlight";
	SLASH_CHATHIGHTLIGHT2 = "/chl";
	
	--add events for saved variables
	ChatHighlightFrame:RegisterEvent("ADDON_LOADED");
	ChatHighlightFrame:RegisterEvent("PLAYER_LOGOUT");

	--Set Events vor login/logout
	ChatHighlightFrame:SetScript("OnEvent", chatHighlight_OnEvent);
end

--handler vor slash commands
function chatHightlight_SlashCommandHandler(msg)
	--0 args
	--clear command
	if(msg == "clear") then
		chatHightlight_clearCommand();
	else
		--1 args
		command, rest = msg:match("([^ ]+) (.*)");
		
		--adds a highlight to the register
		if command == "add" or command == "a" then
		
			--2 more args
			eventKey, filter = rest:match("([^ ]+) (.+)");
			chatHightlight_addCommand(eventKey, filter);
			
		--removs a highlight from the register
		elseif command == "remove" or command == "rm" or command == "r" then
			--2 more args
			eventKey, filterPattern = rest:match("([^ ]+) (.+)");
			chatHightlight_removeCommand(eventKey, filterPattern);
			
		--lists highlights
		elseif command == "list" or command == "l" then
			--1 more arg
			eventKey = rest:match("([^ ]*)");
			chatHightlight_listCommand(eventKey);
		else
		
			--no command found
			print("[CHL] Possible commands with [abbreviation]: [a]dd, [r]emove, [c]lear, [l]ist");
		end
	end
end

--handling add command
function chatHightlight_addCommand(eventKey, filter)
	--nod valid args check
	if eventKey == "" or eventKey == nil or filter == "" or filter == nil then
		print("[CHL] Syntax: /chl add $event $highlight");
		print("[CHL] Valid events: emote, say, yell, public");
		
	elseif eventKeys[eventKey] == nil then
		print(eventKey .. " is not a valid event");
	else
		--count added highlights
		result = 0;
		for _, eventName in ipairs(eventKeys[eventKey]) do
			result = result + chatHightlight_addHighlight(eventName,filter);
		end
		--print result
		print("[CHL] Added ".. result .. " highlights " .. eventKey .. " for filter '" .. filter .. "'.");
	end
end

--helper function for adding highlights
function chatHightlight_addHighlight(event, filter)
	--create event register
	if(highlightRegister[event] == nil) then
		highlightRegister[event] = {};
	end
	--create new entry
	count = table.getn(highlightRegister[event])+1;
	highlightRegister[event][count] = filter;
	
	--register event
	ChatHighlightFrame:RegisterEvent(event);
	return 1;
end

--remove command handler
function chatHightlight_removeCommand(eventKey, filterPattern)
	--valid args check
	if eventKey == "" or eventKey == nil or filterPattern == "" or filterPattern == nil then
		print("[CHL] Syntax: /chl remove $event $highlight");
		print("[CHL] Valid events: emote, say, yell, public");
	elseif eventKeys[eventKey] == nil then
		print(eventKey .. " is not a valid event");
	else
		--count removed entries
		result = 0;
		for _, eventName in ipairs(eventKeys[eventKey]) do
			result = result + removeHighlight(eventName,filterPattern);
		end
		
		--print result
		print("[CHL] Removed "..result.." highlight " .. eventKey .. " for filter '" .. filterPattern .. "'.");
	end
end

--helper function to remove entries
function chatHightlight_removeHighlight(event, filterPattern)
	--check whether reigster exists
	if(highlightRegister[event] == nil) then
		return 0;
	end
	--count removed entries
	result = 0;
	for index, filter in pairs(highlightRegister[event]) do
		if filter:match(filterPattern) ~= nil then
			highlightRegister[event][index] = nil;
			result = result + 1;
		end
	end
	return result;
end

--handler function for clear command
function chatHightlight_clearCommand()
	highlightRegister = {}
	print("[CHL] Cleared all entries.");
end

--handler function for list command
function chatHightlight_listCommand(eventKey)
	--arg check
	if eventKeys[eventKey] == nil then
		print("[CHL] " .. eventKey .. " is not a valid event");
	else
		print("[CHL] List of all found entries for " .. eventKey);
		
		--list all entries
		for _, event in ipairs(eventKeys[eventKey]) do
			if highlightRegister[event] ~= nil then
				for _, filter in pairs(highlightRegister[event]) do
					print("[CHL] " .. event ..": ".. filter);
				end
			end
		end
	end
end

--event method for msg_events
function chatHighlight_OnMsgEvent(self, event, msg, ...)
	--check if this is your event
	if event:match("CHAT_MSG_.*") == nil then
		return
	end
	
	--check register for filters
	filterList = highlightRegister[event];
	for _,filter in pairs(filterList) do
		if string.find(msg,filter) ~= nil then
			highlightMsg = msg:gsub(filter,"~"..filter.."~"); 
			name, realm = UnitName("player");
			SendChatMessage("[CHL] Hightlight: ".. highlightMsg, "WHISPER", nil, name);
		end
	end
end

--event method for login logout events
function chatHighlight_OnAddonLoadedEvent(self, event, addon, ...)
	if addon == "ChatHighlight" then
		-- instantiate register 
		highlightRegister = {};
		
		-- check if saved variables exists
        if SavedHighlightRegister ~= nil then
			-- add highlights again after loading
			for event, list in pairs(SavedHighlightRegister) do
				for _, entry in pairs(list) do
					chatHightlight_addHighlight(event,entry);
				end
			end
		end
	end
end

function chatHightlight_OnLogoutEvent(self,event,...)
    -- Save register
	SavedHighlightRegister = highlightRegister;
end

function chatHighlight_OnEvent(self, event, args)
	--check if this is msg event
	if event:match("CHAT_MSG_.*") ~= nil then
		chatHighlight_OnMsgEvent(self, event, args)
	elseif event == "ADDON_LOADED" then
		chatHighlight_OnAddonLoadedEvent(self,event,args);
	elseif event == "PLAYER_LOGOUT" then
		chatHightlight_OnLogoutEvent(self,event,args);
	end
end