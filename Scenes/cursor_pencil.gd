extends Node2D
@onready var texture := preload("res://Assets/Map/cursor-map.png")

var active := false
var scale_factor := 1.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # sembunyikan cursor asli
	if has_node("Sprite2D"):
		$Sprite2D.texture = texture
	set_process(true)

func _process(delta):
	if active:
		global_position = get_global_mouse_position()
		scale = Vector2(scale_factor, scale_factor)
	else:
		visible = false

func set_active(value: bool):
	active = value
	visible = value

func set_size(new_size: float):
	scale_factor = new_size
