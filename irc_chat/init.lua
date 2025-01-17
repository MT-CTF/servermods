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

	local old_send_me = ctf_chat.send_me
	ctf_chat.send_me = function(name, message, ...)
		old_send_me(name, message, ...)

		local msg = irc.playerMessage(name, message)

		if msg:match("^\x03%d-<") then
			local start_escape = msg:sub(1, msg:find("<")-1)

			-- format is: \startescape < \endescape playername \startescape > \endescape
			msg = msg:gsub("\15(.-)"..start_escape, "* %1"):gsub("[<>]", "")
		end

		irc.say(msg)
	end

	local old_announce = ctf_modebase.announce
	ctf_modebase.announce = function(msg)
		msg = minetest.get_translated_string("en", msg)
		for m in msg:gmatch("[^\n]+") do
			irc.say(m)
		end

		old_announce(msg)
	end
end
