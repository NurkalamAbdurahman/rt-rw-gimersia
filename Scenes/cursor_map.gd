extends Sprite2D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _physics_process(delta: float) -> void:
	global_position = lerp(global_position, get_global_mouse_position(), 16.5*delta)
	
	var desired_rotation: float = -12.5 if Input.is_action_just_pressed("click") else 0.0
	rotation_degrees = lerp(rotation_degrees, desired_rotation, 16.5*delta)
	
	var desired_scale: Vector2 = Vector2(0.35, 0.35) if Input.is_action_just_pressed("click") else Vector2(0.4, 0.4)
	scale = lerp(scale, desired_scale, 16.5*delta)
