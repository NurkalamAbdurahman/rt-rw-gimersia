extends CharacterBody2D

const SPEED = 130.0
@onready var player: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("left", "right")
	input_vector.y = Input.get_axis("up", "down")
	
	input_vector = input_vector.normalized()

	velocity = input_vector * SPEED
	move_and_slide()

	# Flip animasi kalau mau, optional
	if input_vector.x != 0:
		player.flip_h = input_vector.x < 0
