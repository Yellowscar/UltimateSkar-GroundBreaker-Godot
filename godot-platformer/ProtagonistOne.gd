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

#Dash variables
var IsDashing = false 
var DASHSPEED = 800.0
var DASHDIRECTION: float
var CANDASH = true


func _physics_process(delta: float) -> void:
	# Handle Gravity
	print(DIRECTION)
	
	
	#Handle Gravity
	if not is_on_floor():
		velocity.y += Gravity * delta

	# GodotNote - Get the input direction and handle the movement/deceleration.
	# YellowNote - Handle direction, Handle Walking
	if IsDashing == false:
		DIRECTION = Input.get_axis("LEFT", "RIGHT")
		
		if Input.is_action_pressed("LEFT"):
			DASHDIRECTION = -1
	
		if Input.is_action_pressed("RIGHT"):
			DASHDIRECTION = 1
		
	
	#Handle Walking
	if DIRECTION and IsDashing == false:
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
	if is_on_floor():
		#Refresh DASH upon landing
		CANDASH = true
		
		if DIRECTION == 0:
			AnimPlayer.play("Idle Anim")
		
		if Input.is_action_just_pressed("JUMP") and IsDashing == false:
			velocity.y += JUMP_VELOCITY
			AnimPlayer.play("JUMP Anim")
		
	
	else:
		if Input.is_action_just_released("JUMP") and velocity.y < 0:
			velocity.y *= 0.5
	
	#Handle Dashing
	if Input.is_action_just_pressed("ACTION") and CANDASH == true:
		AnimPlayer.play("DASH Anim")
		CANDASH = false
	
	if IsDashing == true:
		velocity.x = DASHDIRECTION * DASHSPEED
	
	
		#flip sprite
	if DIRECTION == -1:
		%"Ulti AnimatedSprite2D".flip_h = true
	if DIRECTION == 1: 
		%"Ulti AnimatedSprite2D".flip_h = false
	move_and_slide()


func StartDashing() -> void:
	Gravity = 0
	velocity.y = 0
	IsDashing = true

func StopDashing() -> void:
	Gravity = DefaultGravity
	IsDashing = false
	
