extends CharacterBody2D

@export var player: Node2D
@export var view_distance: float = 96.0       
@export_range(0, 180) var view_angle_degrees: float = 90.0  
@onready var sight_ray: RayCast2D = $SightRay

@export var cone_color: Color = Color(1.0, 0.85, 0.3, 0.25)  
const CONE_SEGMENTS := 16   #how many segments used to split the sector

@export var turn_speed_degrees: float = 90.0   
@export var scan_angle_degrees: float = 60.0   # how far the guard looks away from its original direction

var base_rotation: float    # the direction the guard was placed facing
var scan_target: float      # the angle the guard is going to turn to

enum State { PATROL, SUSPICIOUS, CHASE, SEARCH }

@export var chase_speed: float = 90.0       
@export var suspicion_time: float = 1.0     #time that the player needs to be seen for to initiate chase 
@export var give_up_time: float = 2.0       #seconds unseen before a suspicious guard goes back to patrol
@export var search_time: float = 4.0        #time spent searching before going back on patrol

var state: State = State.PATROL
var state_timer: float = 0.0     # time spent in the current state
var seen_timer: float = 0.0      # total time the player has been seen (for suspicion_time)
var unseen_timer: float = 0.0    # time since the player was last seen
var last_known_position: Vector2 # where the guard last saw the player


func _ready() -> void:
	base_rotation = rotation
	scan_target = base_rotation + deg_to_rad(scan_angle_degrees)

func _physics_process(delta: float) -> void:
	
	var sees_player := can_see_player()
	if sees_player:
		last_known_position = player.global_position
		unseen_timer = 0.0
	else:
		unseen_timer += delta
	state_timer += delta
	
	match state:
		State.PATROL:
			scan(delta)
			if sees_player:
				change_state(State.SUSPICIOUS)

		State.SUSPICIOUS:
			if sees_player:
				seen_timer += delta
			if seen_timer >= suspicion_time:
				change_state(State.CHASE)
			elif unseen_timer >= give_up_time:
				change_state(State.PATROL)

		State.CHASE:
			if not sees_player:
				change_state(State.SEARCH)
		State.SEARCH:
			if sees_player:
				change_state(State.CHASE)
			elif state_timer >= search_time:
				change_state(State.PATROL)

func can_see_player() -> bool:
	
	if player == null: #to prevent crashing if I  forget to assign the player to each guard
		return false
	
	var to_player: Vector2 = player.global_position - global_position

	#checks if the player is outside of view distance
	if to_player.length() > view_distance:
		return false

	#checks if player is within the cone
	var facing := global_transform.x   
	var half_angle := deg_to_rad(view_angle_degrees / 2.0)
		
	if facing.dot(to_player.normalized()) <= cos(half_angle):
		return false

	#checks if a wall is between guard and player
	sight_ray.target_position = sight_ray.to_local(player.global_position) #points ray from guard to player
	sight_ray.force_raycast_update() 
	if sight_ray.is_colliding() and sight_ray.get_collider() != player:
		return false   #returns false if something is blocking the raycast (that isnt the player)

	return true   #passed every check
	
func _draw() -> void:
	var half_angle := deg_to_rad(view_angle_degrees / 2.0)
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)   # tip of the slice: the guard's centre

	# Walk from one edge of the cone to the other, adding a point on the circle each step.
	for i in range(CONE_SEGMENTS + 1):
		var angle := -half_angle + (2.0 * half_angle) * i / CONE_SEGMENTS
		points.append(rotate_vector(Vector2(view_distance, 0), angle))

	draw_colored_polygon(points, get_cone_colour())

func rotate_vector(v: Vector2, angle: float) -> Vector2:
	var c := cos(angle)
	var s := sin(angle)
	return Vector2(
		c * v.x - s * v.y,   #row 1
		s * v.x + c * v.y    #roe 2
	)


func turn_towards(target_angle: float, delta: float) -> void:
	var difference := angle_difference(rotation, target_angle)    
	var max_step := deg_to_rad(turn_speed_degrees) * delta        
	rotation += clampf(difference, -max_step, max_step)

func scan(delta: float) -> void:
	turn_towards(scan_target, delta)
	if absf(angle_difference(rotation, scan_target)) < 0.01:
		scan_target = 2.0 * base_rotation - scan_target
		
func change_state(new_state: State) -> void:
	state = new_state
	state_timer = 0.0
	seen_timer = 0.0
	unseen_timer = 0.0
	queue_redraw()                                 # redraw the cone in new colour
	print("Guard -> ", State.keys()[new_state])    # shows current state name in Output (debug)

func get_cone_colour() -> Color:
	match state:
		State.SUSPICIOUS, State.SEARCH:
			return Color(1.0, 0.55, 0.1, 0.3)    
		State.CHASE:
			return Color(1.0, 0.15, 0.1, 0.35)   
		_:
			return cone_color                    
