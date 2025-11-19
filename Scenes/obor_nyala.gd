extends Node2D

@onready var sfx_torch_burning: AudioStreamPlayer2D = $SFX_TorchBurning

var player_in_area = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	player_in_area = true
	sfx_torch_burning.play()
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	player_in_area = false
	sfx_torch_burning.stop()
