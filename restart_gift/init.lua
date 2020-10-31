local can_gift = true

minetest.after(60, function() can_gift = false end)

minetest.register_on_joinplayer(function(player)
	if can_gift then
		local pname = player:get_player_name()
		hud_score.new(pname, {
			name = "restart_gift:gift",
			color = 0xc000cd,
			value = 50,
		})

		minetest.chat_send_player(pname, "Thanks for staying with us through that restart!")
	end
end)
