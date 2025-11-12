extends CanvasLayer

@onready var next_stage_button: Button = $Control/Panel/VBoxContainer/VBoxContainer/Next_Stage_Button
@onready var main_menu_button: Button = $Control/Panel/VBoxContainer/VBoxContainer/Main_Menu_Button

@onready var root_control: Control = $Control
@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover

var buttons: Array = []
var selected_index: int = 0

func _ready():
	# Masukkan tombol ke array
	buttons = [next_stage_button, main_menu_button]

	# Connect signal tombol mouse klik
	for btn in buttons:
		btn.pressed.connect(_on_button_pressed)

	# Set fokus awal
	_update_button_focus()

	# Awal popup disembunyikan
	root_control.visible = false

# Panggil fungsi ini dari pintu saat buka
func show_popup():
	root_control.visible = true
	print("pause ini!!!")
	get_tree().paused = true  # Pause game

func hide_popup():
	root_control.visible = false
	print("lewat bang")
	get_tree().paused = false 

func _process(delta):
	if not root_control.visible:
		return

	if Input.is_action_just_pressed("menu_up"):
		selected_index = (selected_index + 1) % buttons.size()
		_update_button_focus()
	elif Input.is_action_just_pressed("menu_down"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_update_button_focus()
	elif Input.is_action_just_pressed("ui_accept"):
		buttons[selected_index].emit_signal("pressed")

func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i == selected_index:
			sfx_hover.play()
			btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # teks emas
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)) # teks abu-abu
			btn.scale = Vector2(1, 1)

func _on_button_pressed():
	sfx_button.play()
	if buttons[selected_index] == next_stage_button:
		hide_popup()
		GameData.reset()
		GameData.clear_data()
		GameData.clear_torch()
		GameData.set_finish_stage3()
		get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_3.tscn")
	elif buttons[selected_index] == main_menu_button:
		hide_popup()
		GameData.reset()
		GameData.clear_data()
		GameData.clear_torch()
		GameData.set_finish_stage3()
		get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")
