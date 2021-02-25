minetest.register_chatcommand("give_score", {
	description = "Give score to player",
	params = "<playername> <amount>",
	privs = {ctf_admin = true},
	func = function(name, params)
		params = string.split(params, " ")

		if not params or #params < 2 then
			return false, "Please provide a player name and the amount of score to give"
		end

		if minetest.get_player_by_name(params[1]) then
			local main = ctf_stats.player(params[1])

			if main then
				main.score = main.score + tonumber(params[2])

				hud_score.new(params[1], {
					name = "score_award:score",
					color = 0xc000cd,
					value = tonumber(params[2])
				})

				ctf_stats.request_save()

				minetest.chat_send_player(params[1], string.format("%s gave you %d score!", name, params[2]))
				return true, string.format("Gave player %s %d score", params[1], tonumber(params[2]))
			else
				return false, "Something went wrong when awarding the score"
			end
		else
			return false, string.format("Player %s not found!", params[1])
		end
	end
})
