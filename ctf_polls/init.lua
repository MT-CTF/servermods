local mods = minetest.get_mod_storage()
local pollfolder = minetest.get_worldpath().."/ctf_polls/"

local function get_table(x)
	if x and x ~= "" then
		return minetest.deserialize(x)
	else
		return {}
	end
end

local saved_poll_names = get_table(mods:get_string("saved_poll_names"))
-- {name1, name2, ...}

local saved_polls      = get_table(mods:get_string("saved_polls")) --[[
{
	poll_name = {
		playerip = "firstplayerip", -- Points to the first IP a player used, which is where we store data
		firstplayerip = {
			poll_votes = {
				vote_1, vote_2, ...
			}

			-- The following is created & populated when the results are printed
			-- It lists any extra names/ips the voter had while opening the vote form
			relations = {ip1, name2, ip3, name1, name3, ip2, ...}
		},
		playername = playerip, -- Basically link to the one with votes attached
		...
	},
	...
}
--]]


local function save_polls()
	local poll_names = {}

	for poll, data in pairs(saved_polls) do
		table.insert(poll_names, poll)
	end

	mods:set_string("saved_polls"     , minetest.serialize(saved_polls))
	mods:set_string("saved_poll_names", minetest.serialize(poll_names ))
end

local polls = {
--[[
	{
		name = "poll name",
		desc = "Should x do y?\nMultiple lines\nAre supported\nbut try to use them sparingly",
		max_votes = 2, -- How many options can be selected simultaneously
		options = {
			"Yes",
			"No",
			"With z",
			"Without z",
		}
	},
--]]
}

local function load_polls_file()
	local found = false

	for _, fname in pairs(minetest.get_dir_list(pollfolder, false)) do
		if fname == "ctf_polls.conf" then
			found = true
			break
		end
	end

	if not found then
		return false, "Poll save file not found"
	end

	local file, err = io.open(pollfolder.."ctf_polls.conf", "r")

	if file then
		local data = file:read("*a")

		file:close()

		local table = minetest.deserialize(data)

		if table then
			polls = table
		else
			return false, "Failed to deserialize data"
		end
	else
		return false, "Failed to load polls: "..dump(err)
	end

	return true
end

-- Load the polls file
do
	local success, err = load_polls_file()

	if not success then
		minetest.log("warning", "[ctf_polls]: "..err)
	end
end

---@param id table {name = playername, ip = playerip}
local function get_saved_data(poll_name, id)
	local poll_data = saved_polls[poll_name]

	assert(poll_name and id, "Wrong number of arguments supplied")

	if not poll_data then return {}, {no_data = true} end

	local data = nil
	local info = {} -- Note that 'nil' may be used in the place of 'false' in some situations

	if type(id.name and poll_data[id.name]) == "string" then
		data = poll_data[ poll_data[id.name] ]
		info.name_points = true

		if
			id.ip and -- IP was supplied and
			not poll_data[id.ip] -- This ip doesn't point to any data
		then
			-- point it to the ip the current pname is associated with
			saved_polls[poll_name][id.ip] = poll_data[id.name]
			info.ip_points = false
		else
			-- Found the data through the playername, but the ip points to it too
			info.ip_points = true
		end
	elseif id.ip then
		data = poll_data[id.ip]
		info.name_points = false

		if type(data) == "string" then
			data = poll_data[data]

			saved_polls[poll_name][id.name] = poll_data[id.ip] -- Point the name to its data
			info.ip_points = true
		elseif type(data) == "table" then
			saved_polls[poll_name][id.name] = id.ip -- Point the name to its data
			info.ip_points = true
		else
			info.ip_points = false
		end
	end

	if type(data) == "table" then
		info.success = true
		return data, info
	else
		info.success = false
		return {}, info
	end
end

local function save_poll_data(name)
	minetest.log("Saving poll "..name.." to file...")
	local file, err = io.open(pollfolder.."poll_"..name..".txt", "w")

	if not file then
		minetest.log("error", err)
	else
		-- Poll results for poll "<Pollname>""
		-- \t	Option 1: x votes (x%)
		-- \t	Option 2: x votes (x%)
		-- ...
		--
		-- All player votes:
		-- \t	ip: name, ip, name, ... | Votes: {Dumped options table}
		-- \t	...

		local total_votes = 0
		local total_option_votes = {}

		for relation, data in pairs(saved_polls[name]) do
			if type(data) ~= "table" then -- 'relation' holds a 'pointer' name/ip, and 'data' is the ip storing the data
				if not saved_polls[name][data].relations then
					saved_polls[name][data].relations = {}
				end

				table.insert(saved_polls[name][data].relations, relation)
			else
				for i, vote in pairs(data.poll_votes) do
					if not total_option_votes[i] then
						total_option_votes[i] = 0
					end

					if vote then
						total_option_votes[i] = total_option_votes[i] + 1
						total_votes = total_votes + 1
					end
				end
			end
		end

		file:write("Poll results for poll ", dump(name), "\n")

		for option, count in ipairs(total_option_votes) do
			file:write("\tOption ", option, ": ", count, " votes (", (count/total_votes) * 100, "%)\n")
		end

		file:write("All voting players:\n")

		for ip, data in pairs(saved_polls[name]) do
			if type(data) == "table" then
				file:write("\t", ip, ": ", table.concat(data.relations, ", "), " | Votes: ", dump(data.poll_votes), "\n")
			end
		end

		file:write("\n---!BEGIN DUMP!---\n", minetest.serialize(saved_polls[name]), "\n---!END DUMP!---\n")

		saved_polls[name] = nil
		save_polls()

		for i, p in pairs(polls) do
			if p.name == name then
				table.remove(polls, i)
				break
			end
		end

		-- Need to update polls file

		file:close()
	end
end

for _, name in pairs(saved_poll_names) do
	local found = false

	for _, data in pairs(polls) do
		if data.name == name then
			found = true
			break
		end
	end

	if not found then
		save_poll_data(name)
	end
end

-- This Function MIT by Rubenwardy
--- Creates a scrollbaroptions for a scroll_container
--
-- @param visible_l the length of the scroll_container and scrollbar
-- @param total_l length of the scrollable area
-- @param scroll_factor as passed to scroll_container
local function make_scrollbaroptions_for_scroll_container(visible_l, total_l, scroll_factor,arrows)

	assert(total_l >= visible_l)

	arrows = arrows or "default"

	local thumb_size = (visible_l / total_l) * (total_l - visible_l)

	local max = total_l - visible_l

	return ("scrollbaroptions[min=0;max=%f;thumbsize=%f;arrows=%s]"):format(max / scroll_factor, thumb_size / scroll_factor,arrows)
end

local format = string.format
local fieldsaves = {}

minetest.register_on_leaveplayer(function(player)
	fieldsaves[player:get_player_name()] = nil
end)

news_markdown.register_tab("Polls", function(name)
	local form = ""

	if not fieldsaves[name] then
		fieldsaves[name] = {}
	end

	local posy = 0.5
	for pollid, data in pairs(polls) do
		local saved_data = get_saved_data(data.name, {name = name, ip = minetest.get_player_ip(name)}).poll_votes or {}

		local _, newlines = data.desc:gsub("\n", "")
		newlines = newlines + 1

		if not fieldsaves[name][data.name] then
			fieldsaves[name][data.name] = {}

			for i=1, #data.options do
				fieldsaves[name][data.name][i] = saved_data[i] or false
			end
		end

		form = format("%stextarea[0.1,%f;24,%f;;;%s]", form, posy, newlines * 0.4, minetest.formspec_escape(data.desc))

		for optionid, label in ipairs(data.options) do
			if saved_data[optionid] ~= nil then
				fieldsaves[name][data.name][optionid] = saved_data[optionid]
			else
				fieldsaves[name][data.name][optionid] = fieldsaves[name][data.name][optionid] or false
			end

			form = format("%s checkbox[0.6,%f;%d_%s_option%d%s;%s;%s]",
				form,
				posy + 0.2 + (newlines * 0.4) + (0.5 * (optionid-1)),
				pollid,
				data.name,
				optionid,
				fieldsaves[name]._refresh_hack and "_" or "",
				minetest.formspec_escape(label),
				fieldsaves[name][data.name][optionid] and "true" or "false"
			)
		end

		posy = posy + 0.5 + (newlines * 0.4) + (0.5 * #data.options)
	end

	local form2 = (posy <= 14 and "" or
			make_scrollbaroptions_for_scroll_container(13.6, math.max(13.6, posy), 0.1, true) ..
			"scrollbar[24.4,0.1;0.5,14.8;vertical;poll_scroll;"..(fieldsaves[name]._scrollbar_pos or 0).."]"
		) ..
		"scroll_container[0.1,0.2;24.1,13.6;poll_scroll;vertical]"

	return form2 .. form .. "scroll_container_end[]"
end,

function(player, formname, fields)
	local name = player:get_player_name()
	local changes = false

	if fieldsaves[name] then
		if fields.poll_scroll then
			fields.poll_scroll = minetest.explode_scrollbar_event(fields.poll_scroll)

			if fields.poll_scroll.type == "CHG" then
				fieldsaves[name]._scrollbar_pos = fields.poll_scroll.value
			end
		end

		for fieldname, value in pairs(fields) do
			local pollid, pollname, option = fieldname:match("^(%d-)_(.-)_option(%d+)")

			if pollid and polls[tonumber(pollid)]    and
			 pollname and fieldsaves[name][pollname] and
			   option and fieldsaves[name][pollname][tonumber(option)] ~= nil
			then
				pollid = tonumber(pollid)
				option = tonumber(option)

				local vote_count = 0
				local playerip = minetest.get_player_ip(name)
				local saved_data, info = get_saved_data(pollname, {name = name, ip = playerip})

				-- Count the current votes
				for i, v in pairs(fieldsaves[name][pollname]) do
					if v then
						vote_count = vote_count + 1
					end
				end

				value = value == "true" and true or false
				if vote_count >= polls[pollid].max_votes then
					value = false
				end

				-- Set the new value
				fieldsaves[name][pollname][option] = value

				-- Update the filesave for votes, or create it if they've fully filled out their votes
				if info.success then
					saved_data.poll_votes[option] = value

					if not info.ip_points then
						saved_polls[pollname][playerip] = info.data_ip
					elseif not info.name_points then
						saved_polls[pollname][name] = info.data_ip
					end
				elseif vote_count + (value and 1 or -1) >= polls[pollid].max_votes then
					if info.no_data then
						saved_polls[pollname] = {}
					end

					saved_polls[pollname][name] = playerip
					saved_polls[pollname][playerip] = {
						poll_votes = fieldsaves[name][pollname]
					}
				end

				changes = true
			end
		end
	end

	if changes then
		save_polls()

		fieldsaves[name]._refresh_hack = not fieldsaves[name]._refresh_hack
		news_markdown.show_news_formspec(name)
	end

	return true
end)

minetest.register_chatcommand("save_poll", {
	description = "End a poll and save it to file",
	params = "<poll name>",
	privs = {server = true},
	func = function(name, poll)
		if not poll or poll == "" then
			return false, "Invalid poll name given"
		end

		if saved_polls[poll] then
			save_poll_data(poll)

			return true, "Saved and closed poll"
		else
			return false, "Poll '"..poll.."' not found"
		end
	end
})

minetest.register_chatcommand("load_polls", {
	description = "Load the polls file",
	privs = {server = true},
	func = function(name)
		local success, msg = load_polls_file()

		if success then
			return true, "Polls file loaded"
		else
			return false, msg
		end
	end
})
