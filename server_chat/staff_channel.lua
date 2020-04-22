local staff = {}
minetest.register_chatcommand("st", {
	params = "<msg>",
	description = "Send a message on the staff channel",
	privs = { kick = true, ban = true },
	func = function(name, param)
		for _, toname in pairs(staff) do
			minetest.chat_send_player(toname, minetest.colorize("#ff9900",
				"<" .. name .. "> " .. param))
			minetest.log("action", "CHAT [STAFFCHANNEL]: <" .. name .. "> " .. param)
		end
	end
})

minetest.register_on_joinplayer(function(player)
	if minetest.check_player_privs(player, { kick = true, ban = true }) then
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
