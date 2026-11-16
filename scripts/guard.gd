extends CharacterBody2D

@export var player: Node2D
@export var view_distance: float = 96.0       
@export_range(0, 180) var view_angle_degrees: float = 90.0  

func _physics_process(_delta: float) -> void:
	#debug test, turns red when the player is seen.
	if can_see_player():
		modulate = Color.RED
	else:
		modulate = Color.WHITE

func can_see_player() -> bool:
	
	if player == null: #to prevent crashing if forget to assign the player to each guard
		return false
	
	var to_player: Vector2 = player.global_position - global_position

	#checks if the player is outside of view distance
	if to_player.length() > view_distance:
		return false

	#checks if player is within the cone. dot product is the cosine of the angle between player and guard
	var facing := Vector2.from_angle(rotation) 
	var half_angle := deg_to_rad(view_angle_degrees / 2.0)
	return facing.dot(to_player.normalized()) > cos(half_angle)
