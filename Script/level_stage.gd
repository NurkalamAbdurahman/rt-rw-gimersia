extends Control

# Catatan: Pastikan GameData.gd memiliki:
# var is_finish_stage1: bool = false
# var is_finish_stage2: bool = false

# Nodes
@onready var stage_1: Button = $Panel/MarginContainer/VBoxContainer/VBoxContainer/stage1
@onready var stage_2: Button = $Panel/MarginContainer/VBoxContainer/VBoxContainer/stage2
@onready var stage_3: Button = $Panel/MarginContainer/VBoxContainer/VBoxContainer/stage3

# Audio
@onready var sfx_hover: AudioStreamPlayer2D = $"../SFX_Hover"
@onready var sfx_start: AudioStreamPlayer2D = $"../SFX_Start"
@onready var sfx_button: AudioStreamPlayer2D = $"../SFX_Button"

# Button state
var all_buttons: Array[Button] = []
var navigatable_buttons: Array[Button] = []
var selected_index: int = 0

# Animation constants
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.6, 0.6, 0.6)
const HOVER_MODULATE: Color = Color(1.0, 1.0, 1.0)
const DISABLED_MODULATE: Color = Color(0.3, 0.3, 0.3, 0.5)
const ANIMATION_DURATION: float = 0.15

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
		stage_1.pressed.connect(_on_stage_1_pressed)
		all_buttons.append(stage_1)
		navigatable_buttons.append(stage_1)
	
	# Setup Stage 2 (Unlock jika Stage 1 selesai)
	if stage_2:
		stage_2.disabled = not GameData.is_finish_stage1
		stage_2.pressed.connect(_on_stage_2_pressed)
		all_buttons.append(stage_2)
		if not stage_2.disabled:
			navigatable_buttons.append(stage_2)
	
	# Setup Stage 3 (Unlock jika Stage 2 selesai)
	if stage_3:
		stage_3.disabled = not GameData.is_finish_stage2
		stage_3.pressed.connect(_on_stage_3_pressed)
		all_buttons.append(stage_3)
		if not stage_3.disabled:
			navigatable_buttons.append(stage_3)
	
	# Disable focus untuk semua tombol (keyboard navigation manual)
	for btn in all_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
	
	# Set selected index ke tombol pertama yang enabled
	selected_index = 0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Navigasi vertikal
	if event.is_action_pressed("menu_up"):
		_move_selection(-1)
	elif event.is_action_pressed("menu_down"):
		_move_selection(1)
	
	# Confirm selection
	elif event.is_action_pressed("ui_accept"):
		if navigatable_buttons.size() > 0:
			_press_selected_button()
	
	# Cancel / Back
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _move_selection(direction: int) -> void:
	if navigatable_buttons.size() == 0:
		return
	
	var prev_index = selected_index
	selected_index = wrapi(selected_index + direction, 0, navigatable_buttons.size())
	
	if prev_index != selected_index:
		sfx_hover.play()
		_update_button_focus()

func _press_selected_button() -> void:
	if navigatable_buttons.size() > 0:
		var btn = navigatable_buttons[selected_index]
		_animate_button_press(btn)
		await get_tree().create_timer(ANIMATION_DURATION).timeout
		btn.emit_signal("pressed")

func _animate_button_press(btn: Button) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION * 0.5)

func _on_button_mouse_entered(btn: Button) -> void:
	var index = navigatable_buttons.find(btn)
	if index != -1:
		selected_index = index
		sfx_hover.play()
		_update_button_focus()

func _on_button_mouse_exited(btn: Button) -> void:
	# Reset to normal state when mouse exits
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
	tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _update_button_focus() -> void:
	for i in range(all_buttons.size()):
		var btn: Button = all_buttons[i]
		var tween: Tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if btn.disabled:
			# Tombol terkunci
			tween.tween_property(btn, "modulate", DISABLED_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)
		elif navigatable_buttons.find(btn) == selected_index:
			# Tombol terpilih
			tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION)
		else:
			# Tombol normal
			tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _on_stage_1_pressed() -> void:
	GameData.hard_reset()
	PuzzleManager.reset_puzzle()
	_load_stage("res://Scenes/FIX/STAGE_1.tscn")

func _on_stage_2_pressed() -> void:
	if stage_2.disabled:
		print("Stage 2 is locked")
		return
	GameData.hard_reset()
	PuzzleManager.reset_puzzle()
	
	_load_stage("res://Scenes/FIX/STAGE_2.tscn")

func _on_stage_3_pressed() -> void:
	if stage_3.disabled:
		print("Stage 3 is locked")
		return
	GameData.hard_reset()
	PuzzleManager.reset_puzzle()
	
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
