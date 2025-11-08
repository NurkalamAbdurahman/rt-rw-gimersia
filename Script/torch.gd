extends Node2D

@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

signal torch_picked_up(torch_node)

var player_in_range

func _on_Torch_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_Torch_body_exited(body):
	if player_in_range and Input.is_action_just_pressed("interract"):
		if body.name == "Player":
			player_in_range = false
			
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interract"):
		emit_signal("torch_picked_up", self)
		set_process(false)
		sprite_2d.visible = false
