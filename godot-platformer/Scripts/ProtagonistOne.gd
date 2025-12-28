extends CharacterBody2D

#Get UltimateSkar's Camera
@onready var UltiCamera = %UltiCamera
#Get AnimationPlayer
@onready var AnimPlayer = %"Ulti Animation Player"

#PlayerState
enum PlayerStates {Normal, Dashing, WallClimbing, CeilingClimbing, Digging, DirtCling, StunStart, Stunned}
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
		if DIRECTION != 0 and is_on_floor() and CurrentPlayerState != PlayerStates.Digging:
			AnimPlayer.play("WALK Anim")
	else:
		if CurrentPlayerState != PlayerStates.Dashing and CurrentPlayerState != PlayerStates.Digging and CurrentPlayerState != PlayerStates.Stunned:
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

#Handle bouncing on enemies/objects
func _on_jump_bounce_hitbox_area_entered(area: Area2D) -> void:
	if Input.is_action_pressed("JUMP"):
		velocity.y = 0
		velocity.y += JUMP_VELOCITY * 1.4
		AnimPlayer.play("JUMP Anim")
	else:
		velocity.y = 0
		velocity.y += JUMP_VELOCITY * 0.8
		AnimPlayer.play("JUMP Anim")

#Climbing Functions
func CeilingClimb():
	if CurrentPlayerState != PlayerStates.Digging or CurrentPlayerState != PlayerStates.DirtCling:
		velocity.y = 0
		CurrentPlayerState = PlayerStates.CeilingClimbing

func WallClimb():
	if CurrentPlayerState != PlayerStates.Digging or CurrentPlayerState != PlayerStates.DirtCling:
		AnimPlayer.stop()
		CurrentPlayerState = PlayerStates.WallClimbing

#Dash functions
func StartDashing() -> void:
	velocity.y = 0
	CurrentPlayerState = PlayerStates.Dashing
	await get_tree().create_timer(0.333).timeout
	if CurrentPlayerState == PlayerStates.Dashing:
		StopDashing()

func StopDashing() -> void:
	CurrentPlayerState = PlayerStates.Normal

#Dig Functions, in need of fixing. 

const OffsetAmount = 30

var DigHurtboxDetected = false

func DiggingFunction():
	%"Digging Hitbox".scale = Vector2(0.8, 0.8)
	%"Digging Hitbox".set_collision_mask_value(4, true)
	DigDirectionX = Input.get_axis("LEFT", "RIGHT")
	DigDirectionY = Input.get_axis("UP", "DOWN")
	
	%"Digging Hitbox".position.x = DigDirectionX * OffsetAmount
	%"Digging Hitbox".position.y = (DigDirectionY * OffsetAmount) + 1
	
	await get_tree().create_timer(0.05).timeout
	
	if CurrentPlayerState != PlayerStates.Digging:
		%"Digging Hitbox".set_collision_mask_value(4, false)
		%"Digging Hitbox".position.x = 0
		%"Digging Hitbox".position.y = 2
		if CurrentPlayerState == PlayerStates.DirtCling:
			CurrentPlayerState = PlayerStates.Normal

func _on_digging_hitbox_area_entered(area: Area2D) -> void:
	CurrentPlayerState = PlayerStates.Digging
	%"Digging Hitbox".set_collision_layer_value(8, true)
	%"Digging Hitbox".set_collision_mask_value(4, false)
	%"Digging Hitbox".scale = Vector2(1, 1)
	
	await get_tree().create_timer(0.05).timeout
	velocity.x = DigDirectionX * DASHSPEED * 1.1
	velocity.y = DigDirectionY * DASHSPEED * 1.1
	
	await get_tree().create_timer(0.005).timeout
	%"Digging Hitbox".set_collision_layer_value(8, false)
	%"Digging Hitbox".scale = Vector2(0, 0)
	%"Digging Hitbox".position.x = 0
	%"Digging Hitbox".position.y = 2
	
	await get_tree().create_timer(0.05).timeout
	if is_on_wall() or is_on_ceiling() or is_on_floor():
		CurrentPlayerState = PlayerStates.DirtCling
	
	if CurrentPlayerState != PlayerStates.DirtCling:
		CurrentPlayerState = PlayerStates.Normal

func DirtCling() -> void:
	velocity.x = 0
	velocity.y = 0
	
	if Input.is_action_just_pressed("JUMP"):
		CurrentPlayerState = PlayerStates.Normal
		velocity.y += JUMP_VELOCITY

func StunFunction() -> void:
	CurrentPlayerState = PlayerStates.Stunned
	velocity.y = -425
	velocity.x = DASHDIRECTION * -1 *  DASHSPEED * 0.7
	await get_tree().create_timer(0.2).timeout
	velocity.y = 425
	velocity.x = DASHDIRECTION * -1 *  DASHSPEED * 0.7
	await get_tree().create_timer(0.2).timeout
	CurrentPlayerState = PlayerStates.Normal

func _physics_process(delta: float) -> void:
	print(CurrentPlayerState)
	
	if CurrentPlayerState == PlayerStates.StunStart:
		StunFunction()
	
	#Testing
	if Input.is_action_just_pressed("TESTACTION"):
		CurrentPlayerState = PlayerStates.StunStart

	
	#Handle Digging
	if CurrentPlayerState == PlayerStates.DirtCling:
		DirtCling()
	
	if Input.is_action_just_pressed("ACTION") and Input.is_action_pressed("DOWN") and is_on_floor():
		DiggingFunction()
	
	if Input.is_action_just_pressed("ACTION") and Input.is_action_pressed("UP") and (is_on_ceiling() or CurrentPlayerState == PlayerStates.Digging):
		DiggingFunction()
	
	if Input.is_action_just_pressed("ACTION") and ((DASHDIRECTION == -1 and Input.is_action_pressed("LEFT") and CurrentPlayerState == PlayerStates.WallClimbing) or (DASHDIRECTION == 1 and Input.is_action_pressed("RIGHT") and CurrentPlayerState == PlayerStates.WallClimbing)):
		DiggingFunction()
	
	if Input.is_action_just_pressed("ACTION") and CurrentPlayerState == PlayerStates.DirtCling:
		DiggingFunction()
	
	
	#Handle Gravity
	if not is_on_floor() and (CurrentPlayerState == PlayerStates.Normal or CurrentPlayerState == PlayerStates.Stunned):
		velocity.y += Gravity * delta

	#Dash Refresh and idle anim
	if is_on_floor() and CurrentPlayerState != PlayerStates.Digging:
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
	if Input.is_action_just_pressed("ACTION") and not Input.is_action_pressed("DOWN") and CANDASH == true and CurrentPlayerState == PlayerStates.Normal:
		StartDashing()
		AnimPlayer.play("DASH Anim")
		CANDASH = false
	
	if CurrentPlayerState == PlayerStates.Dashing:
		velocity.x = DASHDIRECTION * DASHSPEED
		
		if (DASHDIRECTION == 1 and Input.is_action_just_pressed("LEFT")) or (DASHDIRECTION == -1 and Input.is_action_just_pressed("RIGHT")):
			AnimPlayer.play("JUMP Anim")
			StopDashing()
			CurrentPlayerState = PlayerStates.Normal

		
	#Handle climbing
	if is_on_ceiling() and Input.is_action_pressed("UP") and (CurrentPlayerState == PlayerStates.Normal):
		CeilingClimb()
	
	if is_on_wall() and CurrentPlayerState == PlayerStates.CeilingClimbing:
		CeilingClimb()
	
	if CurrentPlayerState == PlayerStates.CeilingClimbing and (Input.is_action_pressed("DOWN") or (not is_on_ceiling() and not is_on_wall())):
		CurrentPlayerState = PlayerStates.Normal
	
	if (CurrentPlayerState == PlayerStates.Dashing) and is_on_wall():
		WallClimb()
	
	if CurrentPlayerState == PlayerStates.WallClimbing: 
		velocity.y = Input.get_axis("UP", "DOWN") * SPEED
		
		if DASHDIRECTION == 1 and Input.is_action_just_pressed("LEFT"):
			CANDASH = true
			CurrentPlayerState = PlayerStates.Normal
		
		if DASHDIRECTION == -1 and Input.is_action_just_pressed("RIGHT"):
			CANDASH = true
			CurrentPlayerState = PlayerStates.Normal
		
		if not is_on_wall() and not is_on_ceiling() and not is_on_floor():
			CANDASH = true
			CurrentPlayerState = PlayerStates.Normal
		
	

	
	
		#flip sprite
	if DIRECTION == -1:
		%"Ulti AnimatedSprite2D".flip_h = true
	if DIRECTION == 1: 
		%"Ulti AnimatedSprite2D".flip_h = false
	move_and_slide()
