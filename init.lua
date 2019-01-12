minetest.register_privilege("ctf_server")
minetest.override_chatcommand("ctf_queue_restart", {
        privs = { ctf_server = true },
})
minetest.override_chatcommand("ctf_unqueue_restart", {
        privs = { ctf_server = true },
})


minetest.override_chatcommand("admin", {
        func = function(name, params)
                return true, "CTF was created by rubenwardy, and this is his server. Please use /report for any issues."
        end
})

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


filter.register_on_violation(function(name, message, total_violations, violations)
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

local old_set = playertag.set
function playertag.set(player, type, color)
	local privs = minetest.get_player_privs(player:get_player_name())
	if privs.interact or not privs.fly then
		return old_set(player, type, color)
	end
end

local old_add_gauge = gauges.add_HP_gauge
function gauges.add_HP_gauge(name)
	local privs = minetest.get_player_privs(name)
	if privs.interact or not privs.fly then
		return old_add_gauge(name)
	end
end

--table.insert(minetest.registered_on_joinplayers, 1, function(player)
--	local name = player:get_player_name()
--	local info = minetest.get_player_information(name)
--	if info.protocol_version < 32 then
--		minetest.kick_player(name, "Please update to 0.4.16. Get newer versions from minetest.net/downloads or by searching for Minetest on the Play Store")
--		return true
--	end
--end)


local function hide_player(player)
	local prop = {
		visual_size = {x = 0, y = 0},
		collisionbox = {0,0,0,0,0,0},
		makes_footstep_sound = false
	}

	player:set_properties(prop)
	player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
end

minetest.register_on_joinplayer(function(player)
	minetest.after(3, function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end

		if not minetest.check_player_privs(name, { fly = true })
				or minetest.check_player_privs(name, { interact = true }) then
			return
		end

		old_set(player, playertag.TYPE_BUILTIN, { a=0, r=255, g=255, b=255 })

		hide_player(player)
	end, player:get_player_name())
end)

-- /whereis chat-command
minetest.register_chatcommand("whereis", {
	params = "<name>",
	description = "Get location of player",
	privs = { kick = true, ban = true, fly = true },
	func = function(name, param)
		if not param or param:trim() == "" then
			return false, "Invalid parameters. See /help whereis"
		end

		param = param:trim()
		local player = minetest.get_player_by_name(param)
		if not player then
			return false, param .. " is not online"
		end
			
		local pos = player:get_pos()
		return true, string.format(param .. " is at %d,%d,%d",
				pos.x, pos.y, pos.z)
	end
}
