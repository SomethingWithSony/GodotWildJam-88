extends CharacterBody3D

@export var health: int = 100

# Movement
@export var max_speed : float = 100
@export var acceleration : float = 10
@export var dash_strength: float = 20

var movement_direction: Vector2 = Vector2.ZERO

# Jump
const GRAVITY: float = -9.8
@export var jump_strength : float = 5

# Combat
var current_damage: float = 1
@onready var camera: Camera3D = $Camera3D
@onready var pivot = $Pivot

func _ready():
	pivot.hide()

func _process(_delta):
	if Input.is_action_just_pressed("slow_down_time"):
		slow_down_time()
		pivot.show()
	
	if Input.is_action_just_released("slow_down_time"):
		reset_time()
		pivot.hide()

func _physics_process(delta):
	current_damage = velocity.length()

	# Gravity Calculations
	if !is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strength
	
	# Movement
	movement_direction = Input.get_vector("left","right","forward","back")
	
	if movement_direction:
		velocity.x = move_toward(velocity.x, movement_direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, movement_direction.y * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
		
	## Cast ray and rotate pivot towards mouse
	var mouse_pos = get_viewport().get_mouse_position()
	var space_state = get_world_3d().direct_space_state
	var origin = camera.project_ray_origin(mouse_pos)
	var end = origin + camera.project_ray_normal(mouse_pos) * 500
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	var result = space_state.intersect_ray(query)
	
	if (!result.is_empty()):
		var look_target : Vector3 = result.position
		var angle = atan2(look_target.x - global_position.x, look_target.z - global_position.z)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, angle , 1)
		
		if Input.is_action_just_pressed("dash"):
			var dash_direction: Vector3 = (look_target - global_position).normalized()
			velocity = dash_direction * dash_strength
			

	#velocity = velocity.move_toward(new_velocity, acceleration)
	move_and_slide()

func slow_down_time():
	Engine.time_scale = 0.2
	
func reset_time():
	Engine.time_scale = 1
	
