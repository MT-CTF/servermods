local gettime = minetest.get_us_time

local queue = {}
local slows = {}
local old_hitboxes = {}

minetest.register_node("anti_blockspam:loading", {
	description = "Visual-only node",
	tiles = {{
		name = "anti_blockspam_loading.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1.0,
		}
	}},
	paramtype = "light",
	light_source = 4,
	sunlight_propagates = true,
	pointable = true,
	diggable = false,
	groups = {not_in_creative_inventory = 1},
	climbable = true
})

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		if def.walkable and def.node_placement_prediction == nil then
			minetest.override_item(name, {
				node_placement_prediction = "anti_blockspam:loading"
			})

			slows[name] = true
		end
	end

	local old_is_protected = minetest.is_protected

	minetest.is_protected = function(pos, name, ...)
		local player = minetest.get_player_by_name(name)
		if player and player:get_player_control().jump and player:get_look_dir().y <= -0.2 and pos.y >= player:get_pos().y+1.5 then
			return true
		end

		local time = gettime()

		if queue[name] and (time - queue[name] < (200000 - ((minetest.get_player_information(name).avg_rtt or 0) * 5e5))) then
			return true
		else
			return old_is_protected(pos, name, ...)
		end
	end
end)

local in_combat = ctf_combat_mode.in_combat
local nodes = minetest.registered_nodes
local HITBOX_CHECK_INTERVAL = 0.6

local function check_hitbox(pname)
	local player = minetest.get_player_by_name(pname)

	if player then
		local pos = player:get_pos()
		if in_combat(player) or (
			nodes[minetest.get_node(pos).name].walkable or nodes[minetest.get_node(pos:offset(0, 1, 0)).name].walkable
		) then
			minetest.after(HITBOX_CHECK_INTERVAL, check_hitbox, pname)
			return
		end

		player:set_properties({selectionbox = old_hitboxes[pname]})
	end

	old_hitboxes[pname] = nil
end

local dist = vector.distance
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if placer and placer:is_player() and in_combat(placer) then
		local ppos = placer:get_pos()
		local pname = placer:get_player_name()

		if slows[newnode.name] and pos.y > ppos.y then
			queue[pname] = gettime()
		end

		if not old_hitboxes[pname] and
		math.min(dist(pos, ppos), dist(pos, ppos:offset(0, 1, 0))) <= 0.6 then
			old_hitboxes[pname] = placer:get_properties().selectionbox
			placer:set_properties({selectionbox = {-0.55, 0.0, -0.55, 0.55, 1.9, 0.55}})
			minetest.after(HITBOX_CHECK_INTERVAL, check_hitbox, pname)
		end
	end
end)
