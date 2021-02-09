minetest.register_on_prejoinplayer(function(name)
	if filter.check_message("", name) == false then
		return "You cannot use that name on this server. Please try a different name."
	end
end)
