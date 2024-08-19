local role_colors = {
    Administrator = "#8b0000",
    Moderator = "#ff6666",
    Guardian = "#ff7f00",
    Builder = "#ffff00",
    VIP = "#0000ff",
    YouTuber = "#9f53ec",
    Contributor = "#82c46c",
}

local function get_player_roles(player)
    local meta = player:get_meta()
    local roles = minetest.deserialize(meta:get_string("roles"))
    return roles or {}
end

local function save_roles_for_player(player, roles)
    local meta = player:get_meta()
    meta:set_string("roles", minetest.serialize(roles))
end

local function add_role(player_name, role)
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return false, "Player not found."
    end

    local roles = get_player_roles(player)
    for _, r in ipairs(roles) do
        if r == role then
            return false, "Player already has this role."
        end
    end

    table.insert(roles, role)
    save_roles_for_player(player, roles)
    return true, "Role successfully added."
end

local function remove_role(player_name, role)
    local player = minetest.get_player_by_name(player_name)
    if not player then
        return false, "Player not found."
    end

    local roles = get_player_roles(player)
    for i, r in ipairs(roles) do
        if r == role then
            table.remove(roles, i)
            save_roles_for_player(player, roles)
            return true, "Role successfully removed."
        end
    end

    return false, "Player does not have this role."
end

minetest.register_chatcommand("rankadd", {
    params = "<player> <role>",
    description = "Add a role to a player",
    privs = {ban=true},
    func = function(name, param)
        local target_player, target_role = param:match("(%S+)%s+(%S+)")
        if not target_player or not target_role then
            return false, "Incorrect syntax. Usage: /rankadd <player> <role>"
        end
        if not role_colors[target_role] then
            return false, "The specified role does not exist."
        end
        local success, message = add_role(target_player, target_role)
        return success, message
    end,
})

minetest.register_chatcommand("rankdelete", {
    params = "<player> <role>",
    description = "Remove a role from a player",
    privs = {ban=true},
    func = function(name, param)
        local target_player, target_role = param:match("(%S+)%s+(%S+)")
        if not target_player or not target_role then
            return false, "Incorrect syntax. Usage: /rankdelete <player> <role>"
        end
        if not role_colors[target_role] then
            return false, "The specified role does not exist."
        end
        local success, message = remove_role(target_player, target_role)
        return success, message
    end,
})

minetest.register_chatcommand("rankinfo", {
    params = "<player>",
    description = "Display roles of a player",
    func = function(name, param)
        local target_player = minetest.get_player_by_name(param)
        if not target_player then
            return false, "Player not found."
        end

        local roles = get_player_roles(target_player)
        if roles and #roles > 0 then
            return true, param .. " has the following roles: " .. table.concat(roles, ", ")
        else
            return false, "The specified player does not have any roles."
        end
    end,
})

minetest.register_chatcommand("ranklist", {
    description = "Display the list of roles with their colors",
    func = function(name, param)
        local role_list = "List of roles:\n"
        for role, color in pairs(role_colors) do
            role_list = role_list .. minetest.colorize(color, role) .. "\n"
        end
        return true, role_list
    end,
})

minetest.register_chatcommand("rankcreate", {
    params = "<rolename> <color_hex>",
    description = "Create a new role with the specified color",
    privs = {ban=true},
    func = function(name, param)
        local role_name, color_hex = param:match("(%S+)%s+(%S+)")
        if not role_name or not color_hex then
            return false, "Incorrect syntax. Usage: /rankcreate <rolename> <color_hex>"
        end
        if role_colors[role_name] then
            return false, "The specified role already exists."
        end
        if not color_hex:match("^#(%x%x%x%x%x%x)$") then
            return false, "Invalid hexadecimal color (# + 6 values)."
        end
        role_colors[role_name] = color_hex
        return true, "Role successfully created: " .. role_name .. " (" .. color_hex .. ")"
    end,
})

minetest.register_chatcommand("rankremove", {
    params = "<rolename>",
    description = "Remove a role from the list",
    privs = {ban=true},
    func = function(name, param)
        local role_name = param:match("^%s*(.-)%s*$")
        if not role_colors[role_name] then
            return false, "The specified role does not exist."
        end
        role_colors[role_name] = nil
        return true, "Role '" .. role_name .. "' successfully removed."
    end,
})

minetest.register_on_chat_message(function(name, message)
    local player = minetest.get_player_by_name(name)
    if player then
        local roles = get_player_roles(player) or {}
        local roles_prefix = ""

        if #roles > 0 then
            for _, current_role in ipairs(roles) do
                if role_colors[current_role] then
                    roles_prefix = roles_prefix .. minetest.colorize(role_colors[current_role], "[" .. current_role .. "] ")
                else
                    roles_prefix = roles_prefix .. "[" .. current_role .. "] "
                end
            end
        end

        minetest.chat_send_all(roles_prefix .. name .. ": " .. message)
        return true
    end
end)
