local can_gift = true
local GIFT_AMOUNT = 50
local gifted = {}

minetest.after(60, function() can_gift = false end)

minetest.register_on_joinplayer(function(player)
	if can_gift then
		local pname = player:get_player_name()
		local main, match = ctf_stats.player(pname)

		if main and match then
			if gifted[pname] then GIFT_AMOUNT = -50 end

			main.score  = main.score  + GIFT_AMOUNT
			match.score = match.score + GIFT_AMOUNT

			ctf_stats.request_save()

			hud_score.new(pname, {
				name = "restart_gift:gift",
				color = 0xc000cd,
				value = GIFT_AMOUNT
			})

			if gifted[pname] then
				GIFT_AMOUNT = -50
				minetest.chat_send_player(pname, "No reward for the greedy.")
				return
			else
				gifted[pname] = true
			end
		end

		minetest.chat_send_player(pname, "Thanks for staying with us through that restart!")
	end
end)
