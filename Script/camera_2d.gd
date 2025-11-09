extends Camera2D

@onready var target: Node2D = $".."


func _physics_process(delta: float) -> void:
	global_position = target.global_position
