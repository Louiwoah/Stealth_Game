extends CharacterBody2D

@export var speed: float = 80.0 

func _physics_process(_delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

# Normalise so diagonal isn't faster
	if direction.length() > 0:
		direction = direction.normalized()
		
	velocity = direction * speed
	move_and_slide()
	
	print(velocity.length())
