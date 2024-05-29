playtime = {}

local os, math = os, math

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

local function divmod(a, b) return math.floor(a / b), a % b end

local function format_duration(seconds)
	local display_hours, seconds_left = divmod(seconds, 3600)
	local display_minutes, display_seconds = divmod(seconds_left, 60)
	return ("%02d:%02d:%02d"):format(display_hours, display_minutes, display_seconds)
end

minetest.register_chatcommand("playtime", {
	params = "[playername]",
	description = S("See your total playtime on this server"),
	func = function(name, player_name)
		if player_name == "" then
            player_name = name
			if minetest.is_singleplayer() then
				player_name = "singleplayer"
			end
        end
		if minetest.get_player_by_name(player_name) then
			return true,
				C("#63d437", "Total: ")..C("#ffea00", format_duration(playtime.get_total_playtime(player_name))).."\n"..
				C("#63d437", "Current: ")..C("#ffea00", format_duration(playtime.get_session_playtime(player_name)))
		else
			if not minetest.player_exists(player_name) then
				return false, S("You must enter a existing player name!")
			end
			return false, S("Player must be online to run this command!")
		end
	end,
})
