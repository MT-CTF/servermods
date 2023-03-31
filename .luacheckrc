unused_args = false
allow_defined_top = true
max_line_length = 999

globals = {
	"minetest",

	"ctf_report", "ctf_modebase", "ctf_chat", "ctf_teams", "ctf_combat_mode",
	"irc", "hpbar",
	"PlayerName",
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn", "indexof"}},

	"ctf_stats",
	"filter",
	"hud_score",
	"dump",
	"unpack",
}

files["spectator_mode/init.lua"].ignore = { "player" }
