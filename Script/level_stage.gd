extends Control

# Nodes
@onready var stage_1: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage1
@onready var stage_2: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage2
@onready var stage_3: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage3

# Audio
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover
@onready var sfx_start: AudioStreamPlayer2D = $SFX_Start

# Button state
var buttons: Array = []
var selected_index: int = 0

# Colors
const LOCKED_COLOR = Color(0.3, 0.3, 0.3, 0.5)
const UNLOCKED_COLOR = Color(0.7, 0.7, 0.7)

func _ready() -> void:
	buttons = []
	
	# Stage 1 disable supaya tidak otomatis terpilih
	if stage_1:
		stage_1.disabled = true
		stage_1.add_theme_color_override("font_color", LOCKED_COLOR)
		buttons.append(stage_1)
	if stage_2:
		stage_2.disabled = not GameData.is_finish_stage1
		stage_2.add_theme_color_override("font_color", LOCKED_COLOR if stage_2.disabled else UNLOCKED_COLOR)
		buttons.append(stage_2)
	if stage_3:
		stage_3.disabled = not GameData.is_finish_stage2
		stage_3.add_theme_color_override("font_color", LOCKED_COLOR if stage_3.disabled else UNLOCKED_COLOR)
		buttons.append(stage_3)

	_update_button_focus()

func _process(delta):
	var prev_index = selected_index

	if Input.is_action_just_pressed("menu_right"):
		selected_index = _next_enabled_index(selected_index, 1)
	elif Input.is_action_just_pressed("menu_left"):
		selected_index = _next_enabled_index(selected_index, -1)

	if prev_index != selected_index:
		_update_button_focus()

	if Input.is_action_just_pressed("ui_accept"):
		var btn = buttons[selected_index]
		if not btn.disabled:
			_on_button_confirmed(btn)

func _next_enabled_index(current: int, direction: int) -> int:
	var count = buttons.size()
	var new_index = current
	for i in range(count):
		new_index = (new_index + direction + count) % count
		if not buttons[new_index].disabled:
			return new_index
	return current

func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn.disabled:
			btn.scale = Vector2(1, 1)
			btn.add_theme_color_override("font_color", LOCKED_COLOR)
			continue
		if i == selected_index:
			if sfx_hover and not sfx_hover.playing:
				sfx_hover.play()
			btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.add_theme_color_override("font_color", UNLOCKED_COLOR)
			btn.scale = Vector2(1, 1)

func _on_button_confirmed(button: Button) -> void:
	var scene_path: String = ""
	if button == stage_2:
		scene_path = "res://Scenes/FIX/STAGE_2.tscn"
	elif button == stage_3:
		scene_path = "res://Scenes/FIX/STAGE_3.tscn"

	if scene_path != "":
		if sfx_start:
			sfx_start.play()
		print("Loading Scene: " + scene_path)
		get_tree().change_scene_to_file(scene_path)
