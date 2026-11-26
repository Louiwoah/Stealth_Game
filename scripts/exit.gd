class_name Exit
extends Area2D

signal player_entered 

func _ready() -> void:
	modulate = Color(0.4, 0.4, 0.4)          
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit()

func light_up() -> void:
	modulate = Color.WHITE 
