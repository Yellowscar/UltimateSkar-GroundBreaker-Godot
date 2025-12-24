extends CharacterBody2D

#Get UltimateSkar's Camera
@onready var UltiCamera = %UltiCamera
#Get AnimationPlayer
@onready var AnimPlayer = %"Ulti Animation Player"

#PlayerState
enum PlayerStates {Normal, Dashing, WallClimbing, CeilingClimbing}
var CurrentPlayerState = PlayerStates.Normal

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
var DASHSPEED = 800.0
var DASHDIRECTION: float = 1
var CANDASH = true

#Digging Variables
var DigDirectionX
var DigDirectionY

#Walking function
func WalkingFunc():
	if DIRECTION and (CurrentPlayerState == PlayerStates.Normal or CurrentPlayerState == PlayerStates.CeilingClimbing):
		velocity.x = DIRECTION * SPEED
		UltiCamera.drag_horizontal_offset = move_toward(UltiCamera.drag_horizontal_offset, 0.15 * DIRECTION, get_process_delta_time() * 1)
		if DIRECTION != 0 and is_on_floor():
			AnimPlayer.play("WALK Anim")
	else:
		if CurrentPlayerState != PlayerStates.Dashing:
			velocity.x = move_toward(velocity.x, 0, SPEED)

# Get horizontal walking direction, as well as DASH direction... 
# which is basically DIRECTION but never set to 0, 
# as to allow DASHING to push you forwards even from a standstill
func DirectionGet():
	if CurrentPlayerState == PlayerStates.Normal or CurrentPlayerState == PlayerStates.CeilingClimbing:
		DIRECTION = Input.get_axis("LEFT", "RIGHT")
		
		if DIRECTION == -1:
			DASHDIRECTION = -1
	
		if DIRECTION == 1:
			DASHDIRECTION = 1


#Climbing Functions
func CeilingClimb():
	Gravity = 0
	velocity.y = 0
	CurrentPlayerState = PlayerStates.CeilingClimbing

func WallClimb():
	Gravity = 0
	
	CurrentPlayerState = PlayerStates.WallClimbing
	AnimPlayer.stop()

#Dash functions
func StartDashing() -> void:
	Gravity = 0
	velocity.y = 0
	CurrentPlayerState = PlayerStates.Dashing

func StopDashing() -> void:
	Gravity = DefaultGravity
	CurrentPlayerState = PlayerStates.Normal

#Dig Functions
func StartDigging() -> void:
	$"Digging Hitbox/CollisionShape2D".scale = Vector2(0.65, 0.65)
	%"Digging Hitbox".set_collision_layer_value(8, true)
	%"Digging Hitbox".set_collision_mask_value(4, true)
	DigDirectionX = Input.get_axis("LEFT", "RIGHT")
	DigDirectionY = Input.get_axis("UP", "DOWN")
	var OffsetAmount = 35
	
	%"Digging Hitbox".position.x = DigDirectionX * OffsetAmount
	%"Digging Hitbox".position.y = (DigDirectionY * OffsetAmount) + 1
	print("Hitbox Active")

func StopDigging() -> void:
	$"Digging Hitbox/CollisionShape2D".scale = Vector2(0.5, 0.5)
	%"Digging Hitbox".set_collision_layer_value(8, false)
	%"Digging Hitbox".set_collision_mask_value(4, false)
	%"Digging Hitbox".position.x = 0
	%"Digging Hitbox".position.y = 1
	print("Hitbox Inactive")

func _on_digging_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Dig Hurtbox"):
		print("I can Dig it!")


func _physics_process(delta: float) -> void:
	# Handle Coyote Timer
	
		#Digging test
	if Input.is_action_just_pressed("TESTACTION"):
		StartDigging()

	if Input.is_action_just_released("TESTACTION"):
		StopDigging()
	
	
	
	
	#Handle Gravity
	if not is_on_floor():
		velocity.y += Gravity * delta

	#Dash Refresh and idle anim
	if is_on_floor():
		#Refresh DASH upon landing
		CANDASH = true
		
		if DIRECTION == 0:
			AnimPlayer.play("Idle Anim")

	# GodotNote - Get the input direction and handle the movement/deceleration.
	# YellowNote - Handle direction, Handle Walking
	DirectionGet()
	WalkingFunc()
	
	#DashCamera
	if CurrentPlayerState == PlayerStates.Dashing:
		UltiCamera.drag_horizontal_offset = move_toward(UltiCamera.drag_horizontal_offset, 0.60 * DASHDIRECTION, get_process_delta_time() * 2)
	
	
	# Handle jump.
	if not is_on_floor() or CurrentPlayerState == PlayerStates.WallClimbing:
		COYOTETIME = move_toward(COYOTETIME, 0, COYOTEDECAY * delta)

	if is_on_floor() or CurrentPlayerState == PlayerStates.WallClimbing:
		COYOTETIME = 0.25

	if COYOTETIME != 0 and CurrentPlayerState != PlayerStates.Dashing and Input.is_action_just_pressed("JUMP"):
			velocity.y = 0
			velocity.y += JUMP_VELOCITY
			AnimPlayer.play("JUMP Anim")
	
	
	
	else:
		if Input.is_action_just_released("JUMP") and velocity.y < 0:
			velocity.y *= 0.5
	
	#Handle Dashing
	if Input.is_action_just_pressed("ACTION") and CANDASH == true and CurrentPlayerState == PlayerStates.Normal:
		AnimPlayer.play("DASH Anim")
		CANDASH = false
	
	if CurrentPlayerState == PlayerStates.Dashing:
		velocity.x = DASHDIRECTION * DASHSPEED
		
		if (DASHDIRECTION == 1 and Input.is_action_just_pressed("LEFT")) or (DASHDIRECTION == -1 and Input.is_action_just_pressed("RIGHT")):
			AnimPlayer.play("JUMP Anim")
			StopDashing()
			CurrentPlayerState = PlayerStates.Normal
	
	#Handle climbing
	if is_on_ceiling() and Input.is_action_pressed("UP") and CurrentPlayerState != PlayerStates.WallClimbing:
		CeilingClimb()
	
	if CurrentPlayerState == PlayerStates.CeilingClimbing and (Input.is_action_pressed("DOWN") or not is_on_ceiling()):
		Gravity = DefaultGravity
		CurrentPlayerState = PlayerStates.Normal
	
	if CurrentPlayerState == PlayerStates.Dashing and is_on_wall():
		WallClimb()
	
	if CurrentPlayerState == PlayerStates.WallClimbing: 
		velocity.y = Input.get_axis("UP", "DOWN") * SPEED
		
		if DASHDIRECTION == 1 and Input.is_action_just_pressed("LEFT"):
			CANDASH = true
			Gravity = DefaultGravity
			CurrentPlayerState = PlayerStates.Normal
		
		if DASHDIRECTION == -1 and Input.is_action_just_pressed("RIGHT"):
			CANDASH = true
			Gravity = DefaultGravity
			CurrentPlayerState = PlayerStates.Normal
		
		if not is_on_wall() and not is_on_ceiling():
			CANDASH = true
			Gravity = DefaultGravity
			CurrentPlayerState = PlayerStates.Normal
		
	

	
	
		#flip sprite
	if DIRECTION == -1:
		%"Ulti AnimatedSprite2D".flip_h = true
	if DIRECTION == 1: 
		%"Ulti AnimatedSprite2D".flip_h = false
	move_and_slide()
