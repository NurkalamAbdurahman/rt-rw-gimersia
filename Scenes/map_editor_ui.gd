extends Control

@onready var draw_area = $DrawArea
@onready var button_back = $Button_Back

func _ready():
	button_back.connect("pressed", Callable(self, "_on_back_pressed"))
	visible = false
	draw_area.visible = false

func open():
	visible = true
	draw_area.visible = true
	draw_area.set_drawing_enabled(true)

func close():
	visible = false
	draw_area.visible = false
	draw_area.set_drawing_enabled(false)

func _on_back_pressed():
	close()
