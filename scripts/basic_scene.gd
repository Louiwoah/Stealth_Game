extends Node2D

var gems_total := 0
var gems_collected := 0
var game_over := false              # ← NEW: stops "caught" or "win" happening twice
@onready var exit_zone: Exit = $Exit

func _ready() -> void:
	for gem in get_tree().get_nodes_in_group("gems"):
		gems_total += 1
		gem.collected.connect(_on_gem_collected)
	print("Gems in level: ", gems_total)

	exit_zone.player_entered.connect(_on_player_reached_exit)

	# ← NEW (moved here from guard.gd): listen to every guard
	for guard in get_tree().get_nodes_in_group("guards"):
		guard.caught_player.connect(_on_player_caught)

func _on_gem_collected() -> void:
	gems_collected += 1
	print("Gems: ", gems_collected, " / ", gems_total)
	if gems_collected == gems_total:
		print("All gems collected, return to start")
		exit_zone.light_up()

func _on_player_reached_exit() -> void:
	if gems_collected < gems_total:
		print("Gems needed:", gems_total - gems_collected)
		return
	win()

func win() -> void:
	if game_over:
		return
	game_over = true
	print("You win!")
	get_tree().paused = true
	restart_level(3.0)

# ← NEW
func _on_player_caught() -> void:
	if game_over:
		return
	game_over = true
	print("Caught!")
	get_tree().paused = true
	restart_level(1.5)

# ← NEW: wait a moment, then reload the whole level from the start
func restart_level(after_seconds: float) -> void:
	await get_tree().create_timer(after_seconds).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
