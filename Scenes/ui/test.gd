extends Node2D

@onready var button: Button = $Button
@onready var you_dead: CanvasLayer = $YouDead

func _ready() -> void:
	button.pressed.connect(on_pressed_button)

func on_pressed_button() -> void:
	you_dead.show_you_dead()
	print("test")
