minetest.register_node("anti_blockspam:loading", {
	description = "Visual-only node",
	tiles = {{
		name = "anti_blockspam_loading.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 0.4,
		}}
	},
	use_texture_alpha = false,
	sunlight_propagates = true,
	pointable = false,
	diggable = false,
	groups = {not_in_creative_inventory = 1},
})

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_nodes) do
		minetest.override_item(name, {
			node_placement_prediction = "anti_blockspam:loading"
		})
	end
end)
