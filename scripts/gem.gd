extends Area2D

signal collected  

@export var gem_frame: int = 4 #4 = red, 5 = green, 24 = blue

func _ready() -> void:
	add_to_group("gems")          
	$Sprite2D.frame = gem_frame
	body_entered.connect(_on_body_entered)   

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collected.emit()           
		queue_free()  
