extends Control

@onready var draw_area = $DrawArea
@onready var button_back = $Button_Back
@onready var sfx_map_open: AudioStreamPlayer2D = $SFX_MapOpen
@onready var sfx_map_close: AudioStreamPlayer2D = $SFX_MapClose

func _ready():
	button_back.connect("pressed", Callable(self, "_on_back_pressed"))
	visible = false
	draw_area.visible = false
	
func _unhandled_input(event):
	if event.is_action_pressed("open_map"):
		if visible:
			close()
		else:
			open()


func open():
	GameData.is_popup_open = true
	visible = true
	draw_area.visible = true
	draw_area.set_drawing_enabled(true)
	if sfx_map_open:
		sfx_map_open.play()

func close():
	GameData.is_popup_open = false
	visible = false
	draw_area.visible = false
	draw_area.set_drawing_enabled(false)
	if sfx_map_close:
		sfx_map_close.play()

func _on_back_pressed():
	close()
