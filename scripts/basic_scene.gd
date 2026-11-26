extends Node2D

var gems_total := 0
var gems_collected := 0
var game_over := false   
@onready var exit_zone: Exit = $Exit
@onready var hud: HUD = $HUD

func _ready() -> void:
	
	for gem in get_tree().get_nodes_in_group("gems"):
		gems_total += 1
		gem.collected.connect(_on_gem_collected)

	exit_zone.player_entered.connect(_on_player_reached_exit)

	
	for guard in get_tree().get_nodes_in_group("guards"):
		guard.caught_player.connect(_on_player_caught)

	hud.set_gems(gems_collected, gems_total)

func _on_gem_collected() -> void:
	gems_collected += 1
	hud.set_gems(gems_collected, gems_total)
	if gems_collected == gems_total:
		exit_zone.light_up()
		hud.show_hint("All gems! Get back to the start", 2.0)    

func _on_player_reached_exit() -> void:
	if gems_collected < gems_total:
		hud.show_hint("Gems needed: %d" % (gems_total - gems_collected), 1.5)  
		return
	win()

func win() -> void:
	if game_over:
		return
	game_over = true
	hud.show_message("You escaped!")                            
	get_tree().paused = true
	restart_level(3.0)

func _on_player_caught() -> void:
	if game_over:
		return
	game_over = true
	hud.show_message("Caught!")                                     
	get_tree().paused = true
	restart_level(1.5)


func restart_level(after_seconds: float) -> void:
	await get_tree().create_timer(after_seconds).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
