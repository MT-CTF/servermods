unused_args = false
allow_defined_top = true
max_line_length = 999

globals = {
	"minetest",
	"irc", "ctf_playertag",
	"gauges", "ctf_hpbar",
	"ctf_teams", "PlayerName",
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn", "indexof"}},

	"ctf_stats",
	"filter",
	"hud_score",
	"dump",
}

files["spectator_mode/init.lua"].ignore = { "player" }
