local spectators = {}

minetest.register_privilege("spectate", {
	description = "Can spectate other players",
	give_to_singleplayer = false
})

minetest.register_chatcommand("watch", {
	params = "<name>",
	description = "Spectate another player",
	privs = {spectate = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "You should be online to be able to spectate another player!"
		end

		if not param or param:trim() == "" then
			return false, "Invalid parameters, see /help watch"
		end

		param = param:trim()
		local target = minetest.get_player_by_name(param)

		if not target then
			return false, "Player " .. param .. " isn't online!"
		end

		if minetest.check_player_privs(target, {spectate = true}) then
			return false, "Can't spectate yourself or another spectator!"
		end

		if player:get_attach() then
			player:set_detach()
		end

		if not spectators[name] then
			spectators[name] = {}
		end

		spectators[name].target = param
		local hud_text = "Spectating " .. param .. "..."
		local hud_id = spectators[name].hud
		if hud_id then
			player:hud_change(hud_id, "text", hud_text)
		else
			spectators[name].hud = player:hud_add({
				hud_elem_type = "text",
				position = {x = 0.5, y = 0.5},
				offset = {x = 0, y = 100},
				alignment = {x = 0, y = 0},
				number = 0x4444CC,
				text = hud_text
			})
		end
		player:set_attach(target, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
		return true, minetest.colorize("#4444CC", hud_text)
	end
})

minetest.register_chatcommand("unwatch", {
	params = "",
	description = "Stop spectating another player",
	privs = {spectate = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "You should be online to run this command!"
		end

		if player:get_attach() then
			player:hud_remove(spectators[name].hud)
			player:set_detach()
			return true, minetest.colorize("#4444CC", "Stopped spectating " ..
					spectators[name].target .. "!")
		end
		spectators[name] = nil

		return true
	end
})

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	for sname, spec in pairs(spectators) do
		-- Spectator left
		if name == sname then
			spectators[sname] = nil
			return
		-- Target left
		elseif name == spec.target then
			minetest.chat_send_player(sname, minetest.colorize("#4444CC",
					"Target left. Stopped spectating " .. spec.target .. "!"))
			local spectator = minetest.get_player_by_name(sname)
			if spectator and spectators[sname].hud then
				spectator:hud_remove(spectators[sname].hud)
			end
			spectators[sname] = nil
			return
		end
	end
end)

local old_set = ctf_playertag.set
function ctf_playertag.set(player, type, color)
	local privs = minetest.get_player_privs(player:get_player_name())
	if not privs.spectate then
		return old_set(player, type, color)
	end
end

local old_add_gauge = gauges.add_HP_gauge
function gauges.add_HP_gauge(name)
	local privs = minetest.get_player_privs(name)
	if not privs.spectate then
		return old_add_gauge(name)
	end
end


local function hide_player(player)
	local prop = {
		pointable = false,
		is_visible = false,
		visual_size  = { x = 0, y = 0 },
		selectionbox = { 0,0,0, 0,0,0 },
		makes_footstep_sound = false
	}

	player:set_properties(prop)
	player:set_armor_groups({ immortal = 1 })
	player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
end

minetest.register_on_joinplayer(function(player)
	minetest.after(3, function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return
		end

		if not minetest.check_player_privs(name, { spectate = true }) then
			return
		end

		player:set_armor_groups({immortal = 1})
		old_set(player, ctf_playertag.TYPE_BUILTIN, { a=0, r=255, g=255, b=255 })

		hide_player(player)
	end, player:get_player_name())
end)

ctf_map.can_cross = function(player)
	return minetest.check_player_privs(player, {spectate = true})
end

-- /whereis chat-command
minetest.register_chatcommand("whereis", {
	params = "<name>",
	description = "Get location of player",
	privs = { spectate = true },
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
})
