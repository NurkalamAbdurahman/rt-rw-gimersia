extends Control
@onready var draw_area = $DrawArea
@onready var button_back = $Button_Back
@onready var sfx_map_open: AudioStreamPlayer2D = $SFX_MapOpen
@onready var sfx_map_close: AudioStreamPlayer2D = $SFX_MapClose

signal map_opened

func _ready():
	button_back.connect("pressed", Callable(self, "_on_back_pressed"))
	visible = false
	draw_area.visible = false
	
func _unhandled_input(event):
	if event.is_action_pressed("open_map"):
		print("🔍 M pressed, current visible state: ", visible)
		if visible:
			print("⬇️ Calling close()")
			close()
		else:
			print("⬆️ Calling open()")
			open()
		get_viewport().set_input_as_handled()

func open():
	print("✅ OPEN() called")
	GameData.is_popup_open = true
	visible = true
	draw_area.visible = true
	draw_area.set_drawing_enabled(true)
	if sfx_map_open:
		sfx_map_open.play()
	emit_signal("map_opened")
	print("📍 After open, visible = ", visible)

func close():
	print("❌ CLOSE() called")
	GameData.is_popup_open = false
	visible = false
	draw_area.visible = false
	draw_area.set_drawing_enabled(false)
	if sfx_map_close:
		sfx_map_close.play()
	print("📍 After close, visible = ", visible)

func _on_back_pressed():
	close()
