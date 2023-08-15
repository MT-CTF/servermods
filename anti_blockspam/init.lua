-- local gettime = minetest.get_us_time

-- local queue = {}
-- local slows = {}

minetest.register_node("anti_blockspam:loading", {
	description = "Visual-only node",
	drawtype = "glasslike",
	tiles = {{
		name = "anti_blockspam_loading.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1.0,
		}}
	},
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
	pointable = true,
	diggable = false,
	groups = {not_in_creative_inventory = 1},
})

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		if def.walkable and def.node_placement_prediction == nil then
			minetest.override_item(name, {
				node_placement_prediction = "anti_blockspam:loading"
			})

			-- slows[name] = true
		end
	end

	-- local old_is_protected = minetest.is_protected

	-- minetest.is_protected = function(pos, name, ...)
	-- 	local time = gettime()

	-- 	if queue[name] and time - queue[name] < 160000 then
	-- 		return true
	-- 	else
	-- 		return old_is_protected(pos, name, ...)
	-- 	end
	-- end
end)

-- local in_combat = ctf_combat_mode.in_combat
-- minetest.register_on_placenode(function(pos, newnode, placer)
-- 	if placer and placer:is_player() and slows[newnode.name] and in_combat(placer) and pos.y > placer:get_pos().y then
-- 		queue[placer:get_player_name()] = gettime()
-- 	end
-- end)
