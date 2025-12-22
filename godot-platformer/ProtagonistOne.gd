extends CharacterBody2D

#Get UltimateSkar's Camera
@onready var UltiCamera = %UltiCamera

#Basic movment variables
var Gravity = 1400.0
const SPEED = 200.0
const JUMP_VELOCITY = -480.0


func _physics_process(delta: float) -> void:
	# Handle Gravity
	if not is_on_floor():
		velocity.y += Gravity * delta

	# Handle jump.
	if is_on_floor():
		if Input.is_action_just_pressed("JUMP"):
			velocity.y += JUMP_VELOCITY
	else:
		if Input.is_action_just_released("JUMP") and velocity.y < 0:
			velocity.y *= 0.5

	# GodotNote - Get the input direction and handle the movement/deceleration.
	# YellowNote - Handle direction, Handle Walking
	var direction := Input.get_axis("LEFT", "RIGHT")
	if direction:
		velocity.x = direction * SPEED
		UltiCamera.drag_horizontal_offset = move_toward(UltiCamera.drag_horizontal_offset, 0.15 * direction, delta * 1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
