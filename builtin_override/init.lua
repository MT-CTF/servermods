minetest.register_privilege("password_admin", {
	description = "Can use /setpassword and /clearpassword on anyone",
	give_to_singleplayer = false,
	give_to_admin = true,
})

local function player_cant_change_target_pass(player, target)
	if not minetest.check_player_privs(player, {password_admin = true}) then
		if minetest.check_player_privs(target, {kick = true}) then
			return true
		end
	end
end

local old_setpassword_func = minetest.registered_chatcommands.setpassword.func
minetest.override_chatcommand("setpassword", {
	func = function(name, param, ...)
		local toname = string.match(param, "^([^ ]+) +.+$")
		if not toname then
			toname = param:match("^([^ ]+) *$")
		end

		if toname and player_cant_change_target_pass(name, toname) then
			return false, "You can't set the password of staff! (Missing: password_admin)"
		end

		return old_setpassword_func(name, param, ...)
	end,
})

local old_clearpassword_func = minetest.registered_chatcommands.clearpassword.func
minetest.override_chatcommand("clearpassword", {
	func = function(name, param, ...)
		if param and param ~= "" then
			if player_cant_change_target_pass(name, param) then
				return false, "You can't clear the password of staff! (Missing: password_admin)"
			end
		end

		return old_clearpassword_func(name, param, ...)
	end,
})
