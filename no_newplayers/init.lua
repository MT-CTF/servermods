local modstorage = minetest.get_mod_storage()

local no_new_players = modstorage:get_int("no_new_players") == 1

minetest.register_on_prejoinplayer(function(name, ip)
	if no_new_players and minetest.get_auth_handler().get_auth(name) == nil then
		return "We aren't accepting new players right now. " ..
				"Please try again another day, contact us on the forums https://forum.minetest.net/viewtopic.php?f=10&t=13157 or on our Discord server https://discord.gg/vcZTRPX"
	end
end)

minetest.register_chatcommand("no_newplayers", {
	description = "Toggle/Check whether new players are allowed or not",
	params = "[yes/no/show]",
	privs = {ban = true},
	func = function(name, param)
		if param then
			if param:find("y") then
				no_new_players = true
				modstorage:set_int("no_new_players", 1)
			elseif param:find("n") then
				no_new_players = false
				modstorage:set_int("no_new_players", 0)
			elseif not param:find("s") and param ~= "" then
				return false, minetest.colorize("#ad00af", "Usage: /no_newplayers [yes/no/show]")
			end
		end

		return true, minetest.colorize(
			"#ad00af",
			"New players are" .. (no_new_players and "n't allowed" or " allowed")
		)
	end,
})
