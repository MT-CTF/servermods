if irc then
	function irc.playerMessage(name, message)
		local pteam = ctf_teams.get(name)

		local color = pteam and ctf_teams.team[pteam].irc_color or 16
		local clear = "\x0F"
		if color then
			color = "\x03" .. color
		else
			color = ""
			clear = ""
		end
		local abrace = color .. "<" .. clear
		local bbrace = color .. ">" .. clear
		return ("%s%s%s %s"):format(abrace, name, bbrace, message)
	end

	ctf_chat.send_me = function(name, message)
		local msg = irc.playerMessage(name, message)
		local start_escape = msg:sub(1, msg:find("<")-1)

		-- format is: \startescape < \endescape playername \startescape > \endescape
		msg = msg:gsub("\15(.-)"..start_escape, "* %1"):gsub("[<>]", "")

		irc.say(msg)
	end

	ctf_modebase.announce = function(msg)
		for m in msg:gmatch("[^\n]+") do
			irc.say(m)
		end
	end
end
