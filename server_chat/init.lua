-- Restrict private messaging to players with a score of 500+
local function canPM(name)
	return minetest.check_player_privs(name, {kick=true}) or ctf_stats.player(name).score > 500
end

local old = minetest.registered_chatcommands["msg"].func
minetest.override_chatcommand("msg", {
	func = function(name, params)
		if canPM(name) then
			return old(name, params)
		else
			return false, "You need at least 500 score to private message!"
		end
	end
})

local oldmail = minetest.registered_chatcommands["mail"].func
minetest.override_chatcommand("mail", {
	func = function(name, params)
		if canPM(name) then
			return oldmail(name, params)
		else
			return false, "You need at least 500 score to private message!"
		end
	end
})

-- Override /ctf_(un)queue_restart to require ctf_server priv
minetest.register_privilege("ctf_server")
minetest.override_chatcommand("ctf_queue_restart", {
	privs = { ctf_server = true },
})
minetest.override_chatcommand("ctf_unqueue_restart", {
	privs = { ctf_server = true },
})

minetest.override_chatcommand("admin", {
	func = function()
		-- lol
		return true, "CTF was created by rubenwardy, and this is his server. Please use /report for any issues."
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

-- Grabs messages from CTF bot's !st <message>
if http and minetest.settings:get("server_chat_relay_from_discord") then
	local time = 0
	minetest.register_globalstep(function(dtime)
		time = time + dtime

		if time <= 5 then
			return
		else
			time = 0
		end

		http.fetch({
			url = "localhost:31337",
			timeout = 5,
			method = "GET",
		}, function(res)
			if res.data == "" then return end

			local messages = minetest.parse_json(res.data)

			if messages and type(messages) == "table" and #messages > 0 then
				minetest.log("action", "CHAT [STAFFCHANNEL]: Sending messages sent from Discord: "..dump(messages))
				for _, toname in pairs(staff) do
					for _, msg in pairs(messages) do
						minetest.chat_send_player(toname, minetest.colorize("#ff9900", msg))
					end
				end
			end
		end)
	end)
end

minetest.register_chatcommand("st", {
	params = "<msg>",
	description = "Send a message on the staff channel",
	privs = { kick = true},
	func = function(name, param)
		local msg = "<" .. name .. "> " .. param
		for _, toname in pairs(staff) do
			minetest.chat_send_player(toname, minetest.colorize("#ff9900", msg))

			minetest.log("action", "CHAT [STAFFCHANNEL]: <" .. name .. "> " .. param)
		end

		-- Send to discord
		if http and minetest.settings:get("server_chat_webhook") then
			http.fetch({
				method = "POST",
				url = minetest.settings:get("server_chat_webhook"),
				extra_headers = {"Content-Type: application/json"},
				timeout = 5,
				data = minetest.write_json({
					username = "Ingame Staff Channel",
					avatar_url = "https://cdn.discordapp.com/avatars/447857790589992966/7ab615bae6196346bac795e66ba873dd.png",
					content = msg,
				}),
			}, function() end)
		end
	end
})

minetest.register_on_joinplayer(function(player)
	if minetest.check_player_privs(player, { kick = true}) then
		table.insert(staff, player:get_player_name())
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	local idx = table.indexof(staff, name)
	if idx ~= -1 then
		table.remove(staff, idx)
	end
end)

-- !players command for discord

minetest.register_chatcommand("players", {
        description = "sends names of players in the game currently to discord",
        func = function()
            local msg = "Connected Players: "
            for _,player in ipairs(minetest.get_connected_players()) do
              msg = msg ..player:get_player_name() ..", "
            end
            minetest.chat_send_all(minetest.colorize("#0D64F3", msg))
		end
})

if http then
	local time = 0
	minetest.register_globalstep(function(dtime)
		time = time + dtime

		if time <= 5 then
			return
		else
			time = 0
		end

		http.fetch({
			url = "127.0.0.1:31338",
			timeout = 5,
			method = "GET",
		}, function(res)
			if res.data == "" then return end
					
			local msg = "Connected Players: "
            for _,player in ipairs(minetest.get_connected_players()) do
              msg = msg ..player:get_player_name() ..", "
            end
					
			if minetest.settings:get("server_chat_webhook") then
						http.fetch({
								method = "POST",
								url = minetest.settings:get("server_chat_webhook"),
								extra_headers = {"Content-Type: application/json"},
								timeout = 5,
								post_data = minetest.write_json({
										username = "TeSt",
										avatar_url = "https://cdn.discordapp.com/avatars/447857790589992966/7ab615bae6196346bac795e66ba873dd.png",
										content = msg,
								}),
						}, function() end)
			end				
		end)
	end)
end
