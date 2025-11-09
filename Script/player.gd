extends CharacterBody2D

const SPEED = 130.0
@onready var player: AnimatedSprite2D = $AnimatedSprite2D
var has_torch = false
var held_torch = null
func _ready() -> void:
	for torch in get_tree().get_nodes_in_group("torches"):
		torch.connect("torch_picked_up", Callable(self, "_on_Torch_picked_up"))

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

	# Flip animasi kalau mau, optional
	if input_vector.x != 0:
		player.flip_h = input_vector.x < 0
