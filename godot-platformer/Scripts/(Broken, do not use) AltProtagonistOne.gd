extends CharacterBody2D

#Get UltimateSkar's Camera
@onready var UltiCamera = %UltiCamera
#Get AnimationPlayer
@onready var AnimPlayer = %"Ulti Animation Player"

#Basic movment variables
@export var DefaultGravity = 1400.0
@export var SPEED = 200.0 
@export var JUMP_VELOCITY = -480.0
var DIRECTION
var Gravity = DefaultGravity
#CoyoteTime
var COYOTETIME = 0
const COYOTEDECAY = 1

#Dash variables
@export var DASHSPEED = 800.0
var DASHDIRECTION: float = 1
var CANDASH = true

#Climbing variables
enum PlayerState {Base, IsDashing, IsWallClimbing, IsCeilingClimbing}
var current_state = PlayerState.Base

func _physics_process(delta: float) -> void:
	
	DIRECTION = Input.get_axis("LEFT", "RIGHT")
	
	if DIRECTION != 0:
		DASHDIRECTION = DIRECTION
	
	match current_state:
		PlayerState.Base:
			HandleBase(delta)
		PlayerState.IsDashing:
			HandleDash(delta)
		PlayerState.IsWallClimbing:
			HandleWallClimb(delta)
		PlayerState.IsCeilingClimbing:
			HandleCeilingClimb(delta)

		#Digging test
	if Input.is_action_just_pressed("TESTACTION"):
		StartDigging()
	if Input.is_action_just_released("TESTACTION"):
		StopDigging()

	# Handle jump.
	if is_on_floor() or current_state == PlayerState.IsWallClimbing:
		COYOTETIME = 0.25
	else:
		COYOTETIME = move_toward(COYOTETIME, 0, COYOTEDECAY * delta)
		
	if COYOTETIME > 0 and Input.is_action_just_pressed("JUMP"):
			velocity.y = 0
			velocity.y += JUMP_VELOCITY
			AnimPlayer.play("JUMP Anim")
	else:
		if Input.is_action_just_released("JUMP") and velocity.y < 0:
			velocity.y *= 0.5
	
	#Handle Walking
	if DIRECTION:
		velocity.x = DIRECTION * SPEED
		UltiCamera.drag_horizontal_offset = move_toward(UltiCamera.drag_horizontal_offset, 0.15 * DIRECTION, delta * 1)
		if DIRECTION != 0 and is_on_floor():
			AnimPlayer.play("WALK Anim")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if Input.is_action_just_pressed("ACTION") and CANDASH == true:
		AnimPlayer.play("DASH Anim")
		CANDASH = false
		
	#Handle climbing
	if is_on_ceiling() and Input.is_action_pressed("UP") and current_state != PlayerState.IsWallClimbing:
		current_state = PlayerState.IsCeilingClimbing
	
		#flip sprite
	if DIRECTION == -1:
		%"Ulti AnimatedSprite2D".flip_h = true
	if DIRECTION == 1: 
		%"Ulti AnimatedSprite2D".flip_h = false
	move_and_slide()

func HandleBase(delta):
	#Handle Gravity
	if not is_on_floor():
		velocity.y += Gravity * delta

	#Dash Refresh and idle anim
	if is_on_floor():
		#Refresh DASH upon landing
		CANDASH = true
		if DIRECTION == 0:
			AnimPlayer.play("Idle Anim")
			
	
	

func HandleDash(delta):
	#DashCamera
	UltiCamera.drag_horizontal_offset = move_toward(UltiCamera.drag_horizontal_offset, 0.60 * DASHDIRECTION, get_process_delta_time() * 2)
	velocity.x = DASHDIRECTION * DASHSPEED
		
	if (DASHDIRECTION == 1 and Input.is_action_just_pressed("LEFT")) or (DASHDIRECTION == -1 and Input.is_action_just_pressed("RIGHT")):
		AnimPlayer.play("JUMP Anim")
		current_state = PlayerState.Base
	if is_on_wall():
		current_state = PlayerState.IsWallClimbing
#Climbing Functions


func HandleWallClimb(delta):
	velocity.y = Input.get_axis("UP", "DOWN") * SPEED
	if not is_on_wall():
		CANDASH = true
		current_state = PlayerState.Base
		

func HandleCeilingClimb(delta):
	velocity.y = 0
	
	if Input.is_action_pressed("DOWN") or not is_on_ceiling():
		current_state = PlayerState.Base
#Dash functions
func StartDashing() -> void:
	velocity.y = 0
	current_state = PlayerState.IsDashing
	COYOTETIME = 0

#Dig Functions
func StartDigging() -> void:
	$"Digging Hitbox/CollisionShape2D".scale = Vector2(1, 1)
	%"Digging Hitbox".set_collision_layer_value(8, true)
	print("Hitbox Active")

func StopDigging() -> void:
	$"Digging Hitbox/CollisionShape2D".scale = Vector2(0.5, 0.5)
	%"Digging Hitbox".set_collision_layer_value(8, false)
	print("Hitbox Inactive")

func _on_digging_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Dig Hurtbox"):
		print("I can Dig it!")
