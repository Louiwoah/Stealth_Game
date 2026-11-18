extends Node2D

var gems_total := 0
var gems_collected := 0

func _ready() -> void:
	
	for gem in get_tree().get_nodes_in_group("gems"):
		gems_total += 1
		gem.collected.connect(_on_gem_collected)
	print("Gems in level: ", gems_total)

func _on_gem_collected() -> void:
	gems_collected += 1
	print("Gems: ", gems_collected, " / ", gems_total)
	if gems_collected == gems_total:
		print("All gems collected, return to start")
