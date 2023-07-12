minetest.register_privilege("password_admin", {
	description = "Can use /setpassword and /clearpassword on anyone",
	give_to_singleplayer = false,
	give_to_admin = true,
})

minetest.override_chatcommand("kill", {
	privs = {ban=true},
})

local function player_cant_change_target_pass(player, target)
	return not minetest.check_player_privs(player, {password_admin = true}) and minetest.check_player_privs(target, {kick = true})
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

if filter then
	minetest.register_on_mods_loaded(function()
		local old_me_func = minetest.registered_chatcommands["me"].func
		minetest.override_chatcommand("me", {
			func = function(name, param, ...)
				if not filter.check_message(name, param) then
					filter.on_violation(name, param)
					return false, "No swearing"
				end

				return old_me_func(name, param, ...)
			end
		})
	end)
end
