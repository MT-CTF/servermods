playtime = {}

local os = os
local math = math
local string = string

local current = {}

local key = "playtime:time"

local S = minetest.get_translator("playtime")
local C = minetest.colorize

--get playtime
function playtime.get_current_playtime(name)
	if current[name] then
		return os.time() - current[name]
	else
		return 0
	end
end

--get total playtime
function playtime.get_total_playtime(name)
	local player = minetest.get_player_by_name(name)
	if player then
		return player:get_meta():get_int(key) + playtime.get_current_playtime(name)
	end
end

--reset playtime
function playtime.remove_playtime(name)
	local player = minetest.get_player_by_name(name)
	if player then
		player:get_meta():set_int(key, 0)
	end
end

if minetest.is_singleplayer() then
	minetest.register_on_shutdown(function()
		local player = minetest.get_connected_players()[1]
		if player then
			local name = player:get_player_name()
			local meta = player:get_meta()
			meta:set_int(key, meta:get_int(key) + playtime.get_current_playtime(name))
			current[name] = nil
		end
	end)
else
	minetest.register_on_leaveplayer(function(player)
		local name = player:get_player_name()
		local meta = player:get_meta()
		meta:set_int(key, meta:get_int(key) + playtime.get_current_playtime(name))
		current[name] = nil
	end)
end

minetest.register_on_joinplayer(function(player)
	current[player:get_player_name()] = os.time()
end)

local function SecondsToClock(seconds)
	--local seconds = tonumber(seconds)

	if seconds <= 0 then
		return "00:00:00"
	else
		local hours = string.format("%02.f", math.floor(seconds/3600));
		local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
		return hours..":"..mins..":"..secs
	end
end

minetest.register_chatcommand("playtime", {
	params = "",
	description = S("Get how much time you played"),
	func = function(name)
		if minetest.get_player_by_name(name) then
			--return true, "Total: "..SecondsToClock(playtime.get_total_playtime(name)).." Current: "..SecondsToClock(playtime.get_current_playtime(name))
			return true,
				C("#63d437", "Total: ")..C("#ffea00", SecondsToClock(playtime.get_total_playtime(name))).."\n"..
				C("#63d437", "Current: ")..C("#ffea00", SecondsToClock(playtime.get_current_playtime(name)))
		else
			return false, S("You must be connected to run this command!")
		end
	end,
})