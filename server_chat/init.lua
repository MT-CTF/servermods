local http = minetest.request_http_api()
local storage = minetest.get_mod_storage()

minetest.override_chatcommand("admin", {
	func = function()
		-- lol
		return true, "CTF was created by rubenwardy. The current admin/developer is LandarVargan.\nPlease use /report for any issues."
	end
})

minetest.register_chatcommand("discord", {
	description = "Join our Discord server!",
	func = function(name)
		minetest.chat_send_player(name, "Join our Discord server here: https://discord.gg/vcZTRPX")
		return true
	end,
})

minetest.register_chatcommand("selfkick", {
	description = "Kick yourself",
	func = function(name)
		minetest.kick_player(name, "Requested self-kick")
	end
})

minetest.register_chatcommand("players", {
	description = "List the players currently online",
	func = function(name, param)
		local players = minetest.get_connected_players()
		local out = #players .. " player(s) online: "

		for _, p in pairs(players) do
			out = out .. p:get_player_name() .. ", "
		end

		return true, out:sub(1, -3)
	end
})

-- Shadowmute command

local shadowmutes = {}

minetest.register_chatcommand("shadowmute", {
	description = "Mute a player without notifying them of it",
	params = "<player name> [time]",
	privs = {ban = true},
	func = function(name, params)
		if params and params ~= "" then
			params = string.split(params, " ")
			local player_ip = minetest.get_player_ip(params[1])

			if params[2] then -- Shadowmute with timer
				local time_amount, time_unit = params[2]:match("(%d+)(.)")

				if not time_amount or not time_unit then
					return false, "Invalid time format. Valid time units: S(econds), M(inutes), H(ours), D(ays). Example time: 12D"
				end

				local amount = tonumber(time_amount)
				if time_unit:match("[sS]") then
					time_unit = "sec"
				elseif time_unit:match("[mM]") then
					time_unit = "min"
					amount = amount * 60
				elseif time_unit:match("[hH]") then
					time_unit = "hour"
					amount = amount * 60 * 60
				elseif time_unit:match("[dD]") then
					time_unit = "day"
					amount = amount * 60 * 60 * 24
				else
					return false, "Invalid time unit"
				end

				shadowmutes[player_ip or params[1]] = os.time() + amount

				return true, "Shadowmuted "..(player_ip or params[1]).." for "..time_amount..time_unit
			else -- Shadowmute without timer
				shadowmutes[player_ip or params[1]] = true

				return true, "Shadowmuted "..(player_ip or params[1]).." until next server restart"
			end
		end

		return false, "You need to specify a player to shadowmute!"
	end,
})

minetest.register_chatcommand("unshadowmute", {
	description = "Remove a shadowmute from a player",
	params = "<player ip>",
	privs = {ban = true},
	func = function(name, params)
		if params and params ~= "" then
			if shadowmutes[params] then
				shadowmutes[params] = nil

				return true, "Shadowmute removed"
			else
				return false, "The given IP is invalid or not shadowmuted"
			end
		end

		return false, "You must supply an IP address"
	end
})

minetest.register_on_chat_message(function(name, message)
	if message:sub(1,1) == "/" then return end

	local ip = minetest.get_player_ip(name)

	if shadowmutes[ip] then
		if shadowmutes[ip] ~= true and os.time() >= shadowmutes[ip] then
			shadowmutes[ip] = nil
			return
		end

		local pteam = ctf_teams.get(name)
		if pteam then
			minetest.chat_send_player(name, minetest.colorize(ctf_teams.team[pteam].color, "<" .. name .. "> ") .. message)
		else
			minetest.chat_send_player(name, "<" .. name .. "> " .. message)
		end

		return true
	end
end)

-- Make sure muted player is muted by IP, which we can only get when they're online
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local ip = minetest.get_player_ip(name)

	if shadowmutes[name] then
		if not shadowmutes[ip] then
			shadowmutes[ip] = shadowmutes[name]
		end

		shadowmutes[name] = nil
	end
end)

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

-- Staff Channel

local function grab_staff_messages()
	http.fetch({
		url = "localhost:31337",
		timeout = 10,
		method = "GET",
	}, function(res)
		if res.data == "" then return end

		local messages = minetest.parse_json(res.data)

		if messages and type(messages) == "table" and #messages > 0 then
			minetest.log("action", "[server_chat]: Sending messages sent from Discord: " .. dump(messages))

			local msg = ""
			for _, m in pairs(messages) do
				msg = msg .. "[STAFF]: " .. m .. "\n"
			end

			for toname in pairs(ctf_report.staff) do
				minetest.chat_send_player(toname, minetest.colorize("#ffcc00", msg))
			end
		end
	end)

	minetest.after(5, grab_staff_messages)
end

-- Grabs messages from CTF bot's !x <message>
if http and minetest.settings:get("server_chat_relay_from_discord") then
	minetest.after(5, grab_staff_messages)
end

local function send_staff_message(msg, prefix, discord_prefix, discord_webhook, send_ingame)
	minetest.log("action", "[server_chat] " .. prefix .. msg)

	if send_ingame ~= false then
		for toname in pairs(ctf_report.staff) do
			minetest.chat_send_player(toname, minetest.colorize("#ffcc00", prefix .. msg))

			minetest.sound_play("ctf_report_bell", {
				to_player = toname,
				gain = 1.4,
				pitch = 1.4,
			}, true)
		end
	end

	-- Send to discord
	if http and minetest.settings:get(discord_webhook) then
		http.fetch({
			method = "POST",
			url = minetest.settings:get(discord_webhook),
			extra_headers = {"Content-Type: application/json"},
			timeout = 10,
			data = minetest.write_json({
				username = discord_prefix,
				avatar_url = "https://cdn.discordapp.com/avatars/447857790589992966/7ab615bae6196346bac795e66ba873dd.png",
				content = msg,
			}),
		}, function() end)
	else
		minetest.log("warning", "[server_chat] Discord webhook isn't configured. http is "..(http and "enabled" or "not enabled")..". Webhook is "..dump(minetest.settings:get(discord_webhook)))
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

-- IRC mods

local function get_irc_mods()
	return storage:get_string("irc_mods"):split(",")
end

local function add_irc_mod(name)
	local mods = get_irc_mods()
	if table.indexof(mods, name) > 0 then
		return false
	end
	mods[#mods + 1] = name
	storage:set_string("irc_mods", table.concat(mods, ","))
	minetest.log("action", "[irc_mods]: " .. name .. " subscribed to IRC reports")
	return true
end

local function remove_irc_mod(name)
	local mods = get_irc_mods()
	local idx = table.indexof(mods, name)
	if idx > 0 then
		table.remove(mods, idx)
		storage:set_string("irc_mods", table.concat(mods, ","))
		minetest.log("action", "[irc_mods]: " .. name .. " unsubscribed from IRC reports")
		return true
	end
	return false
end

minetest.register_chatcommand("report_sub", {
	privs = { kick = true },
	func = function(name, param)
		if param:lower():trim() == "remove" then
			if remove_irc_mod(name) then
				return true, "Successfully removed!"
			else
				return false, "Unable to remove, are you even subscribed?"
			end
		else
			if add_irc_mod(name) then
				return true, "Successfully added!"
			else
				return false, "Unable to add, are you already subscribed?"
			end
		end
	end
})

local old_send_report = ctf_report.send_report
ctf_report.send_report = function(msg)
	if irc then
		for _, toname in pairs(get_irc_mods()) do
			if not minetest.get_player_by_name(toname) then
				minetest.chat_send_player(toname, msg)
			end
		end
	end

	send_staff_message(msg, "[REPORT]: ", "Ingame Report", "reports_webhook", false)

	old_send_report(msg)
end

local commands = {"kick", "ban", "unban", "tempban", "revoke", "shadowmute"}
for _, cmd in pairs(commands) do
	if minetest.registered_chatcommands[cmd] then
		local oldcmdfunc = minetest.registered_chatcommands[cmd].func
		minetest.override_chatcommand(cmd, {
			func = function(name, params, ...)
				local returns = {oldcmdfunc(name, params, ...)}

				if returns then
					if returns[1] == true then
						send_staff_message(name.." ran command: `/"..cmd.." " .. params.."`", "[STAFF]: ", "Staff Command", "reports_webhook", true)
					end

					return unpack(returns)
				end
			end
		})
	else
		minetest.log("[server_chat]: Command "..cmd.." doesn't exist")
	end
end
