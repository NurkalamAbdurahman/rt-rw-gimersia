extends Control

@onready var stage_1: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage1
@onready var stage_2: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage2
@onready var stage_3: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage3

var buttons: Array = []
var selected_index: int = 0

@onready var sfx_hover: AudioStreamPlayer = $SFX_Hover

func _ready() -> void:
	# Masukkan semua tombol ke array
	buttons = [stage_1, stage_2, stage_3]

	# Connect signal tombol klik mouse
	for btn in buttons:
		btn.pressed.connect(_on_button_pressed)

	# Set fokus awal
	_update_button_focus()

func _process(delta):
	if Input.is_action_just_pressed("menu_right"):
		selected_index = (selected_index + 1) % buttons.size()
		_update_button_focus()
	elif Input.is_action_just_pressed("menu_left"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_update_button_focus()
	elif Input.is_action_just_pressed("ui_accept"):
		buttons[selected_index].emit_signal("pressed")

func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i == selected_index:
			if sfx_hover:
				sfx_hover.play()
			btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # teks emas
			btn.scale = Vector2(1.12, 1.12) # sedikit membesar
		else:
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)) # teks abu-abu
			btn.scale = Vector2(1, 1) # normal

func _on_button_pressed():
	pass
