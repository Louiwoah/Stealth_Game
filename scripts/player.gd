extends CharacterBody2D

@export var speed: float = 80.0 

@export var turn_speed_degrees: float = 720.0  
@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

# Normalise so diagonal isn't faster
	if direction.length() > 0:
		direction = direction.normalized()
		
	velocity = direction * speed
	move_and_slide()
	
	if direction != Vector2.ZERO:
		var target_angle := direction.angle()
		var max_step := deg_to_rad(turn_speed_degrees) * delta
		sprite.rotation += clampf(angle_difference(sprite.rotation, target_angle), -max_step, max_step)
