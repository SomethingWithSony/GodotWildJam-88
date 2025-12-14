extends CharacterBody3D

@export var health: int = 100

# Movement
@export var max_speed : float = 100
@export var acceleration : float = 10
@export var dash_strength: float = 30
@export var bounce_strength: float = 15 
var movement_direction: Vector2 = Vector2.ZERO

# Jump
const GRAVITY: float = -9.8
@export var jump_strength : float = 5

# Combat
var current_damage: float = 1
@onready var camera: Camera3D = $Camera3D
@onready var pivot: Node3D = $Pivot
@onready var attack_area: Area3D = $AttackArea
@onready var dash_attack_timer: Timer = $DashAttackTimer
var in_slow_motion: bool = false

func _ready():
	pivot.hide()
	attack_area.monitoring = false
	# Ensure attack area detects enemies even if physics body ignores them
	attack_area.collision_mask = 2

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
		
		if Input.is_action_just_pressed("dash") and in_slow_motion:
			var dash_direction: Vector3 = (look_target - global_position).normalized()
			start_dashing(dash_direction)
			
	move_and_slide()

func start_dashing(target_pos: Vector3):
	velocity = target_pos * dash_strength
	
	# Turn on attack collision detection
	attack_area.monitoring = true
	
	# Turn of collision with enemies - Layer 2
	set_collision_mask_value(2, false)
	
	dash_attack_timer.start()

func end_dash():
	# Turn off  attack collision detection
	attack_area.monitoring = false
	
	# Turn on collision with enemies - Layer 2
	set_collision_mask_value(2, false)
	
func slow_down_time():
	Engine.time_scale = 0.2
	in_slow_motion = true
	
func reset_time():
	Engine.time_scale = 1
	in_slow_motion = false

func _on_attack_area_body_entered(body):
	if body is Enemy:
		var is_dead = body.take_damage(current_damage)
		
		if is_dead:
			# Do nothing
			# The enemy dies and the player phases trough it
			pass
		else:
			# Bounce off the enemy
			var bounce_direction = (global_position - body.global_position).normalized()
			
			# Bounce off immediately
			velocity = bounce_direction * bounce_strength
			
			# Ensure we dont hit an enemy twice
			end_dash()
			dash_attack_timer.stop()
			
func _on_dash_attack_timer_timeout():
	end_dash()
