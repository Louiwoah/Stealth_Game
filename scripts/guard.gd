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
@export var search_time: float = 8.0        #time spent searching before going back on patrol

var state: State = State.PATROL
var state_timer: float = 0.0     # time spent in the current state
var last_known_position: Vector2 # where the guard last saw the player

@export var detect_time_near: float = 0.3    # seconds to fill the meter at point-blank range
@export var detect_time_far: float = 1.5     # seconds to fill it at the edge of vision
@export var meter_drain_time: float = 2.0    # seconds for a full meter to empty when unseen

var detection: float = 0.0   # the detection meter: 0 = not noticed, 1 = fully detected


@export var walk_speed: float = 50.0   #speed when returning to post or searching
var home_position: Vector2             # where the guard was placed, so it can return after a chase

@onready var state_icon: Sprite2D = $StateIcon
const ICON_QUESTION := 3 
const ICON_EXCLAIM := 23

@export var level: LevelMap              # assign the LevelMap node in the Inspector
var path := PackedVector2Array()         # the waypoints still to walk through
var path_target := Vector2.INF 

@export var move_turn_speed_degrees: float = 360.0

func _ready() -> void:
	base_rotation = rotation
	scan_target = base_rotation + deg_to_rad(scan_angle_degrees)
	home_position = global_position
	update_icon()

func _physics_process(delta: float) -> void:
	
	var sees_player := can_see_player()
	if sees_player:
		last_known_position = player.global_position
	update_detection(sees_player, delta)   # fill or drain the meter this frame
	state_timer += delta
	
	match state:
		State.PATROL:
			# walks back to post and starts looking around again
			if move_towards(home_position, walk_speed, delta):
				scan(delta)
			if sees_player:
				change_state(State.SUSPICIOUS)

		State.SUSPICIOUS:
			#stops and looks around for player
			turn_towards((last_known_position - global_position).angle(), delta)
			if detection >= 1.0:
				change_state(State.CHASE) 
			elif detection <= 0.0:
				change_state(State.PATROL)

		State.CHASE:
			#run towards the player
			move_towards(player.global_position, chase_speed, delta)
			if not sees_player:
				change_state(State.SEARCH)

		State.SEARCH:
			#Go to where the player was last seen, then spins slodwly to look around.
			if move_towards(last_known_position, walk_speed, delta):
				rotation += deg_to_rad(turn_speed_degrees) * delta
			if sees_player:
				change_state(State.CHASE)
			elif state_timer >= search_time:
				change_state(State.PATROL)
				
	state_icon.global_rotation = 0.0
	state_icon.global_position = global_position + Vector2(0, -14)
	if state == State.SUSPICIOUS:
		state_icon.modulate = Color.WHITE.lerp(Color.RED, detection)
	else:
		state_icon.modulate = Color.WHITE

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


func turn_towards(target_angle: float, delta: float, speed_degrees: float = turn_speed_degrees) -> void:
	var difference := angle_difference(rotation, target_angle)    
	var max_step := deg_to_rad(speed_degrees) * delta       
	rotation += clampf(difference, -max_step, max_step)

func scan(delta: float) -> void:
	turn_towards(scan_target, delta)
	if absf(angle_difference(rotation, scan_target)) < 0.01:
		scan_target = 2.0 * base_rotation - scan_target
		
func change_state(new_state: State) -> void:
	state = new_state
	state_timer = 0.0
	queue_redraw()   
	update_icon()                              #redraw the cone in new colour
	print("Guard -> ", State.keys()[new_state])    #shows current state name in Output (debug)

func get_cone_colour() -> Color:
	match state:
		State.SUSPICIOUS, State.SEARCH:
			return Color(1.0, 0.55, 0.1, 0.3)    
		State.CHASE:
			return Color(1.0, 0.15, 0.1, 0.35)   
		_:
			return cone_color                    

func move_towards(target: Vector2, speed: float, delta: float) -> bool:
	if global_position.distance_to(target) < 4.0:
		velocity = Vector2.ZERO
		path.clear()
		path_target = Vector2.INF
		return true
	if level != null and target.distance_to(path_target) > 8.0:
		path = level.find_path(global_position, target)
		path_target = target
		if not path.is_empty():
			path.remove_at(0)
	if not path.is_empty() and global_position.distance_to(path[0]) < 3.0:
		path.remove_at(0)
		
	var next_point: Vector2 = target if path.is_empty() else path[0]
	var to_next := next_point - global_position
	velocity = to_next.normalized() * speed
	turn_towards(to_next.angle(), delta, move_turn_speed_degrees)
	move_and_slide()
	return false

func update_icon() -> void:
	match state:
		State.SUSPICIOUS, State.SEARCH:
			state_icon.visible = true
			state_icon.frame = ICON_QUESTION
		State.CHASE:
			state_icon.visible = true
			state_icon.frame = ICON_EXCLAIM
		_:
			state_icon.visible = false

func update_detection(sees_player: bool, delta: float) -> void:
	if sees_player:
		var distance := global_position.distance_to(player.global_position)
		var closeness := 1.0 - clampf(distance / view_distance, 0.0, 1.0)   
		closeness = closeness * closeness             
		var fill_rate := lerpf(1.0 / detect_time_far, 1.0 / detect_time_near, closeness)
		detection += fill_rate * delta
	else:
		detection -= delta / meter_drain_time
	detection = clampf(detection, 0.0, 1.0)
