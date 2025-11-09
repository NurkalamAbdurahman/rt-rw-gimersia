extends CharacterBody2D

const SPEED = 130.0
@onready var player: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_run: AudioStreamPlayer2D = $SFX_Run_Stone

var has_torch = false
var held_torch = null

func _ready() -> void:
	for torch in get_tree().get_nodes_in_group("torches"):
		torch.connect("torch_picked_up", Callable(self, "_on_torch_picked_up"))

func _on_torch_picked_up(torch_node):
	if not has_torch:
		held_torch = torch_node
		has_torch = true
		held_torch.get_parent().remove_child(held_torch)
		add_child(held_torch)
		held_torch.position = Vector2(0, 10)

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("left", "right")
	input_vector.y = Input.get_axis("up", "down")
	input_vector = input_vector.normalized()

	velocity = input_vector * SPEED
	move_and_slide()

	# Flip animasi
	if input_vector.x != 0:
		player.flip_h = input_vector.x < 0

	# 🎧 Mainkan / hentikan langkah kaki
	if input_vector.length() > 0:
		# Kalau belum main, play
		if not sfx_run.playing:
			sfx_run.play()
	else:
		# Kalau diam, stop
		if sfx_run.playing:
			sfx_run.stop()
