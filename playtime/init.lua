playtime = {}

local os, math, string = os, math, string

local current = {}

local key = "playtime:time"

local S = minetest.get_translator("playtime")
local C = minetest.colorize

function playtime.get_session_playtime(name)
	if current[name] then
		return os.time() - current[name]
	else
		return 0
	end
end

function playtime.get_total_playtime(name)
	local player = minetest.get_player_by_name(name)
	if player then
		return player:get_meta():get_int(key) + playtime.get_session_playtime(name)
	end
end

function playtime.reset_playtime(name)
	local player = minetest.get_player_by_name(name)
	if player then
		player:get_meta():set_int(key, 0)
	end
end

--do NOT work in singleplayer
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	local meta = player:get_meta()
	meta:set_int(key, meta:get_int(key) + playtime.get_session_playtime(name))
	current[name] = nil
end)


minetest.register_on_joinplayer(function(player)
	current[player:get_player_name()] = os.time()
end)

local function get_clock(seconds)
	if seconds <= 0 then
		return "00:00:00"
	else
		local hours = string.format("%02.f", tostring(math.floor(seconds/3600)))
		local mins = string.format("%02.f", tostring(math.floor(seconds/60 - hours*60)))
		local secs = string.format("%02.f", tostring(math.floor(seconds - hours*3600 - mins*60)))
		return hours..":"..mins..":"..secs
	end
end

minetest.register_chatcommand("playtime", {
	params = "",
	description = S("Get how long you played"),
	func = function(name)
		if minetest.get_player_by_name(name) then
			return true,
				C("#63d437", "Total: ")..C("#ffea00", get_clock(playtime.get_total_playtime(name))).."\n"..
				C("#63d437", "Current: ")..C("#ffea00", get_clock(playtime.get_session_playtime(name)))
		else
			return false, S("You must be connected to run this command!")
		end
	end,
})
