local storage = minetest.get_mod_storage()

disallowed_names = minetest.deserialize(storage:get_string("disallowed_names")) or {"sex","fuc","drug","suicid"}

minetest.register_on_prejoinplayer(function(name)
    for _, dn in pairs(disallowed_names) do
        if string.find(name:lower(), dn:lower()) then
            return "You cannot use that name on this server. Please try a different name."
        end
    end
end)

-- Command to add a name to disallowed names
minetest.register_chatcommand("bdname_add", {
    params = "<name>",
    privs = { ban = true },
    description = "Adds a name to the disallowed names list.",
    func = function(name,param)
		if param ~= "" then
			table.insert(disallowed_names, tostring(param))
			storage:set_string("disallowed_names", minetest.serialize(disallowed_names))

			return true, "Added " .. param .. " to the list of banned names"
		else
			return false, "You need to provide a name to add")
		end
    end
})

--removes a name from disallowed names
minetest.register_chatcommand("bdname_remove",{
    description = "removes a name from disallowed names",
    params = "<name>",
    privs = { ban = true },
    func = function(name, param)
        if param ~= "" then
            for k in pairs(disallowed_names) do
                if param == disallowed_names[k] then
                    table.remove(disallowed_names, k)
                end
            end
            storage:set_string("disallowed_names", minetest.serialize(disallowed_names))
			
			return true, "Removed" .. param .. "from the list of banned names"
        else
			return false, "You need to provide a name to remove"
        end
    end
})

-- List of disallowed names
minetest.register_chatcommand("bdname_list", {
    description = "Lists all the disallowed names.",
    privs = {ban = true},
    func = function(name)
		local output = ""
		for _, bn in pairs(disallowed_names) do
			output = output .. bn .. "\n"
		end
		
		return true, output:sub(1, -2)
    end
})
