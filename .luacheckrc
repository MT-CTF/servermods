unused_args = false
allow_defined_top = true
max_line_length = 999

globals = {
	"ctf", "minetest",
	"irc", "ctf_playertag",
	"gauges",
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn", "indexof"}},

	"ctf_stats",
	"filter",
	"hud_score",
}

files["spectator_mode/init.lua"].globals = { "ctf_map" }
files["spectator_mode/init.lua"].ignore = { "player" }
