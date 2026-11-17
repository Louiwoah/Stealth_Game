extends CharacterBody2D

@export var player: Node2D
@export var view_distance: float = 96.0       
@export_range(0, 180) var view_angle_degrees: float = 90.0  
@onready var sight_ray: RayCast2D = $SightRay

func _physics_process(_delta: float) -> void:
	#debug test, turns red when the player is seen.
	if can_see_player():
		modulate = Color.RED
	else:
		modulate = Color.WHITE

func can_see_player() -> bool:
	
	if player == null: #to prevent crashing if I  forget to assign the player to each guard
		return false
	
	var to_player: Vector2 = player.global_position - global_position

	#checks if the player is outside of view distance
	if to_player.length() > view_distance:
		return false

	#checks if player is within the cone
	var facing := Vector2.from_angle(rotation) 
	var half_angle := deg_to_rad(view_angle_degrees / 2.0)
		
	if facing.dot(to_player.normalized()) <= cos(half_angle):
		return false

	#checks if a wall is between guard and player
	sight_ray.target_position = sight_ray.to_local(player.global_position) #points ray from guard to player
	sight_ray.force_raycast_update() 
	if sight_ray.is_colliding() and sight_ray.get_collider() != player:
		return false   #returns false if something is blocking the raycast (that isnt the player)

	return true   # passed every check
