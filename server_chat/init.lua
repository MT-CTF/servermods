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

local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"
dofile(modpath .. "staff_channel.lua")
