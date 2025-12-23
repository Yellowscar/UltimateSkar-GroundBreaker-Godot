extends CharacterBody2D

#Get UltimateSkar's Camera
@onready var UltiCamera = %UltiCamera
#Get AnimationPlayer
@onready var AnimPlayer = %"Ulti Animation Player"

#Basic movment variables
const DefaultGravity = 1400.0
var Gravity = DefaultGravity
const SPEED = 200.0 
const JUMP_VELOCITY = -480.0
var DIRECTION

#CoyoteTime
var COYOTETIME = 0
const COYOTEDECAY = 1

#Dash variables
var IsDashing = false 
var DASHSPEED = 800.0
var DASHDIRECTION: float = 1
var CANDASH = true

#Climbing variables
var IsCeilingClimbing = false
var IsWallClimbing = false

#Climbing Functions
func CeilingClimb():
	Gravity = 0
	velocity.y = 0
	
	IsCeilingClimbing = true

func WallClimb():
	Gravity = 0
	
	IsWallClimbing = true
	IsDashing = false

#Dash functions
func StartDashing() -> void:
	Gravity = 0
	velocity.y = 0
	IsDashing = true

func StopDashing() -> void:
	Gravity = DefaultGravity
	IsDashing = false
	

func _physics_process(delta: float) -> void:
	# Handle Coyote Timer
	
	print(COYOTETIME)
	
	#Handle Gravity
	if not is_on_floor():
		velocity.y += Gravity * delta

	# GodotNote - Get the input direction and handle the movement/deceleration.
	# YellowNote - Handle direction, Handle Walking
	if IsDashing == false and IsWallClimbing == false:
		DIRECTION = Input.get_axis("LEFT", "RIGHT")
		
		if Input.is_action_pressed("LEFT"):
			DASHDIRECTION = -1
	
		if Input.is_action_pressed("RIGHT"):
			DASHDIRECTION = 1
		
	
	#Handle Walking
	if DIRECTION and IsDashing == false and IsWallClimbing == false:
		velocity.x = DIRECTION * SPEED
		UltiCamera.drag_horizontal_offset = move_toward(UltiCamera.drag_horizontal_offset, 0.15 * DIRECTION, delta * 1)
		if DIRECTION != 0 and is_on_floor():
			AnimPlayer.play("WALK Anim")
	else:
		if IsDashing == false:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	#DashCamera
	if IsDashing == true:
		UltiCamera.drag_horizontal_offset = move_toward(UltiCamera.drag_horizontal_offset, 0.60 * DASHDIRECTION, get_process_delta_time() * 2)
	
	
	# Handle jump.
	if not is_on_floor() or IsWallClimbing:
		COYOTETIME = move_toward(COYOTETIME, 0, COYOTEDECAY * delta)

	if is_on_floor() or IsWallClimbing == true:
		COYOTETIME = 0.25

	if COYOTETIME != 0 and IsDashing == false and Input.is_action_just_pressed("JUMP"):
			velocity.y = 0
			velocity.y += JUMP_VELOCITY
			AnimPlayer.play("JUMP Anim")
	
	
	#Dash Refresh and idle anim
	if is_on_floor():
		#Refresh DASH upon landing
		CANDASH = true
		
		if DIRECTION == 0:
			AnimPlayer.play("Idle Anim")
		
		
		

		
	
	else:
		if Input.is_action_just_released("JUMP") and velocity.y < 0:
			velocity.y *= 0.5
	
	#Handle Dashing
	if Input.is_action_just_pressed("ACTION") and CANDASH == true:
		AnimPlayer.play("DASH Anim")
		CANDASH = false
	
	if IsDashing == true:
		velocity.x = DASHDIRECTION * DASHSPEED
		
		if (DASHDIRECTION == 1 and Input.is_action_just_pressed("LEFT")) or (DASHDIRECTION == -1 and Input.is_action_just_pressed("RIGHT")):
			AnimPlayer.play("JUMP Anim")
			StopDashing()
			IsDashing = false
	
	#Handle climbing
	if is_on_ceiling() and Input.is_action_pressed("JUMP") and IsWallClimbing == false:
		CeilingClimb()
	
	if IsCeilingClimbing == true and (Input.is_action_pressed("DOWN") or not is_on_ceiling()):
		Gravity = DefaultGravity
		IsCeilingClimbing = false
	
	if IsDashing == true and is_on_wall():
		WallClimb()
	
	if IsWallClimbing == true: 
		velocity.y = Input.get_axis("UP", "DOWN") * SPEED
		
		if DASHDIRECTION == 1 and Input.is_action_just_pressed("LEFT"):
			CANDASH = true
			Gravity = DefaultGravity
			IsWallClimbing = false
		
		if DASHDIRECTION == -1 and Input.is_action_just_pressed("RIGHT"):
			CANDASH = true
			Gravity = DefaultGravity
			IsWallClimbing = false
		
		if not is_on_wall() and not is_on_ceiling():
			CANDASH = true
			Gravity = DefaultGravity
			IsWallClimbing = false
	
	
	
		#flip sprite
	if DIRECTION == -1:
		%"Ulti AnimatedSprite2D".flip_h = true
	if DIRECTION == 1: 
		%"Ulti AnimatedSprite2D".flip_h = false
	move_and_slide()
