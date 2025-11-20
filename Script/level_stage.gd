extends Control

# Catatan: Pastikan GameData.gd memiliki:
# var is_finish_stage1: bool = false
# var is_finish_stage2: bool = false

# Nodes
@onready var stage_1: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage1
@onready var stage_2: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage2
@onready var stage_3: Button = $MarginContainer/VBoxContainer/HBoxContainer/stage3

# Audio
@onready var sfx_hover: AudioStreamPlayer2D = $"../SFX_Hover"
@onready var sfx_start: AudioStreamPlayer2D = $"../SFX_Start"
@onready var sfx_button: AudioStreamPlayer2D = $"../SFX_Button"

# Button state
var all_buttons: Array[Button] = []
var navigatable_buttons: Array[Button] = []
var selected_index: int = 0

# Colors
const LOCKED_COLOR = Color(0.3, 0.3, 0.3, 0.5)
const UNLOCKED_COLOR = Color(0.7, 0.7, 0.7)
const SELECTED_COLOR = Color(1.0, 0.84, 0.0)

func _ready() -> void:
	_setup_buttons()
	_update_button_focus()
	set_process_input(true)

func _setup_buttons() -> void:
	all_buttons.clear()
	navigatable_buttons.clear()
	
	# Setup Stage 1 (Selalu tersedia)
	if stage_1:
		stage_1.disabled = false
		stage_1.modulate = UNLOCKED_COLOR
		stage_1.pressed.connect(_on_stage_1_pressed)
		all_buttons.append(stage_1)
		navigatable_buttons.append(stage_1)
	
	# Setup Stage 2 (Unlock jika Stage 1 selesai)
	if stage_2:
		stage_2.disabled = not GameData.is_finish_stage1
		stage_2.modulate = LOCKED_COLOR if stage_2.disabled else UNLOCKED_COLOR
		stage_2.pressed.connect(_on_stage_2_pressed)
		all_buttons.append(stage_2)
		if not stage_2.disabled:
			navigatable_buttons.append(stage_2)
	
	# Setup Stage 3 (Unlock jika Stage 2 selesai)
	if stage_3:
		stage_3.disabled = not GameData.is_finish_stage2
		stage_3.modulate = LOCKED_COLOR if stage_3.disabled else UNLOCKED_COLOR
		stage_3.pressed.connect(_on_stage_3_pressed)
		all_buttons.append(stage_3)
		if not stage_3.disabled:
			navigatable_buttons.append(stage_3)
	
	# Disable focus untuk semua tombol (keyboard navigation manual)
	for btn in all_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Set selected index ke tombol pertama yang enabled
	selected_index = 0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	var prev_index = selected_index
	
	# Navigasi horizontal
	if event.is_action_pressed("menu_right") or event.is_action_pressed("ui_right"):
		_move_selection(1)
	elif event.is_action_pressed("menu_left") or event.is_action_pressed("ui_left"):
		_move_selection(-1)
	
	# Confirm selection
	elif event.is_action_pressed("ui_accept"):
		if navigatable_buttons.size() > 0:
			navigatable_buttons[selected_index].emit_signal("pressed")
	
	# Cancel / Back
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
	
	# Update visual jika index berubah
	if prev_index != selected_index:
		_update_button_focus()

func _move_selection(direction: int) -> void:
	
	if navigatable_buttons.size() == 0:
		return
	
	# Move to next/previous enabled button
	selected_index = (selected_index + direction) % navigatable_buttons.size()
	sfx_hover.play()
	
	# Handle wrap around
	if selected_index < 0:
		selected_index = navigatable_buttons.size() - 1
	
	# Play hover sound

func _update_button_focus() -> void:
	# Reset semua tombol ke state default
	for btn in all_buttons:
		if btn.disabled:
			btn.modulate = LOCKED_COLOR
			btn.scale = Vector2(1, 1)
		else:
			btn.modulate = UNLOCKED_COLOR
			btn.scale = Vector2(1, 1)
	
	# Highlight tombol yang dipilih
	if navigatable_buttons.size() > 0 and selected_index < navigatable_buttons.size():
		var selected_btn = navigatable_buttons[selected_index]
		selected_btn.modulate = SELECTED_COLOR
		selected_btn.scale = Vector2(1.12, 1.12)

func _on_stage_1_pressed() -> void:
	_load_stage("res://Scenes/FIX/STAGE_1.tscn")

func _on_stage_2_pressed() -> void:
	if stage_2.disabled:
		print("Stage 2 is locked")
		return
	_load_stage("res://Scenes/FIX/STAGE_2.tscn")

func _on_stage_3_pressed() -> void:
	if stage_3.disabled:
		print("Stage 3 is locked")
		return
	_load_stage("res://Scenes/FIX/STAGE_3.tscn")

func _load_stage(scene_path: String) -> void:
	if sfx_start:
		sfx_start.play()
	print("Loading Scene: " + scene_path)
	
	# Disable semua tombol untuk mencegah double-click
	for btn in all_buttons:
		btn.disabled = true
	
	# Load scene dengan fade transition jika ada
	var fade_scene = load("res://Scenes/ui/fade_transitions.tscn")
	if fade_scene:
		var fade_instance = fade_scene.instantiate()
		get_tree().root.add_child(fade_instance)
		await fade_instance.fade_out()
	
	get_tree().change_scene_to_file(scene_path)

func _on_back_pressed() -> void:
	if sfx_button:
		sfx_button.play()
	print("Back to main menu")
	visible = false
	
	# Notify parent bahwa panel ditutup
	if get_parent().has_method("_on_panel_closed"):
		get_parent()._on_panel_closed()
