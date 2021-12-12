minetest.override_chatcommand("admin", {
	func = function()
		-- lol
		return true, "Admins are Lone_Wolf and savilli. Please use /report for any issues."
	end
})

-- Disable IRC bot-command /whereis
if irc then
	irc.bot_commands["whereis"] = nil
end

-- on_violation callback for the filter mod
-- Decreases player health by 6 HP upon every violation
if filter then
	filter.register_on_violation(function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local hp = player:get_hp()
			if hp > 3*2 then
				hp = hp - 3*2
			else
				hp = 1
			end
			player:set_hp(hp)
		end
	end)
end

--
--
--- Staff Channel
--- Moved here because http api can't be requested unless in the main file
--
--

local staff = {}
local http = minetest.request_http_api()

local function grab_staff_messages()
	http.fetch({
		url = "localhost:31337",
		timeout = 5,
		method = "GET",
	}, function(res)
		if res.data == "" then return end

		local messages = minetest.parse_json(res.data)

		if messages and type(messages) == "table" and #messages > 0 then
			minetest.log("action", "[server_chat]: Sending messages sent from Discord: " .. dump(messages))
			for toname in pairs(staff) do
				for _, msg in pairs(messages) do
					minetest.chat_send_player(toname, minetest.colorize("#ffcc00", "[STAFF] " .. msg))
				end
			end
		end
	end)

	minetest.after(5, grab_staff_messages)
end

-- Grabs messages from CTF bot's !x <message>
if http and minetest.settings:get("server_chat_relay_from_discord") then
	minetest.after(5, grab_staff_messages)
end

local function send_staff_message(msg, prefix, discord_prefix, discord_webhook)
	minetest.log("action", string.format("[server_chat] " .. prefix .. msg))
	for toname in pairs(ctf_report.staff) do
		minetest.chat_send_player(toname, minetest.colorize("#ffcc00", prefix .. msg))
	end

	-- Send to discord
	if http and minetest.settings:get(discord_webhook) then
		http.fetch({
			method = "POST",
			url = minetest.settings:get(discord_webhook),
			extra_headers = {"Content-Type: application/json"},
			timeout = 5,
			data = minetest.write_json({
				username = discord_prefix,
				avatar_url = "https://cdn.discordapp.com/avatars/447857790589992966/7ab615bae6196346bac795e66ba873dd.png",
				content = msg,
			}),
		}, function() end)
	end
end

minetest.register_chatcommand("x", {
	params = "<msg>",
	description = "Send a message on the staff channel",
	privs = { kick = true },
	func = function(name, param)
		send_staff_message(string.format("<%s> %s", name, param), "[STAFF]: ", "Ingame Staff Channel", "server_chat_webhook")
	end
})

ctf_report.send_report = function(msg)
	send_staff_message(msg, "[REPORT]: ", "Ingame Report", "reports_webhook")
end
