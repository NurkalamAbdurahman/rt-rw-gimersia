extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Quit
@onready var control_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Control
@onready var stage_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Stage
@onready var creadit_button: Button = $MarginContainer2/Creadit

@onready var creadit_panel: Control = $Creadit
@onready var stage_level: Control = $StageLevel
@onready var control_panel: Panel = $Control2

@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover
@onready var sfx_start: AudioStreamPlayer2D = $SFX_Start
@onready var bgm: AudioStreamPlayer2D = $BGM

@onready var video_stream_player: VideoStreamPlayer = $Creadit/TextureRect/VideoStreamPlayer

var is_panel_open: bool = false
var selected_index: int = 0
var navigatable_buttons: Array[Button] = []

const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const NORMAL_MODULATE: Color = Color(0.6, 0.65, 0.7)
const HOVER_MODULATE: Color = Color(0.9, 0.95, 1.0)
const DISABLED_MODULATE: Color = Color(0.3, 0.3, 0.3, 0.5)
const ANIMATION_DURATION: float = 0.15

func _ready() -> void:
	_load_and_loop_bgm("res://Assets/Audio/bgm.ogg")
	_setup_navigatable_buttons()
	_connect_button_signals()
	_update_button_visuals()
	_hide_all_panels()
	set_process_input(true)

func _load_and_loop_bgm(path: String) -> void:
	var new_stream = load(path)
	if new_stream is AudioStreamOggVorbis:
		new_stream.loop = true
		bgm.stream = new_stream
		bgm.play()

func _setup_navigatable_buttons() -> void:
	navigatable_buttons.clear()
	navigatable_buttons.append(start_button)

	if GameData.is_finish_stage1:
		navigatable_buttons.append(stage_button)
		stage_button.disabled = false
	else:
		stage_button.disabled = true

	navigatable_buttons.append(control_button)
	navigatable_buttons.append(quit_button)
	navigatable_buttons.append(creadit_button)

	# Mouse interaction dihilangkan => nonaktifkan mouse
	for btn in navigatable_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _connect_button_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	control_button.pressed.connect(_on_control_pressed)
	stage_button.pressed.connect(_on_stage_pressed)
	creadit_button.pressed.connect(_on_creadit_pressed)

func _hide_all_panels() -> void:
	control_panel.visible = false
	creadit_panel.visible = false
	stage_level.visible = false

func _input(event: InputEvent) -> void:
	if is_panel_open:
		if event.is_action_pressed("ui_cancel"):
			_close_all_panels()
		return

	if event.is_action_pressed("menu_down"):
		_navigate_menu(1)

	elif event.is_action_pressed("menu_up"):
		_navigate_menu(-1)

	elif event.is_action_pressed("ui_accept"):
		_activate_selected_button()

func _navigate_menu(direction: int) -> void:
	if navigatable_buttons.is_empty():
		return

	selected_index = (selected_index + direction) % navigatable_buttons.size()
	if selected_index < 0:
		selected_index = navigatable_buttons.size() - 1

	var iterations = 0
	while navigatable_buttons[selected_index].disabled and iterations < navigatable_buttons.size():
		selected_index = (selected_index + direction) % navigatable_buttons.size()
		if selected_index < 0:
			selected_index = navigatable_buttons.size() - 1
		iterations += 1

	_play_sfx(sfx_hover)
	_update_button_visuals()

func _activate_selected_button() -> void:
	if navigatable_buttons[selected_index].disabled:
		return
	navigatable_buttons[selected_index].emit_signal("pressed")

func _update_button_visuals() -> void:
	for i in range(navigatable_buttons.size()):
		var btn = navigatable_buttons[i]
		if btn.disabled and btn != stage_button:
			continue

		var is_selected = (i == selected_index and not is_panel_open)

		if is_selected:
			_animate_button(btn, HOVER_SCALE, HOVER_MODULATE)
		else:
			_animate_button(btn, NORMAL_SCALE, NORMAL_MODULATE)

	if stage_button.disabled:
		_animate_button(stage_button, NORMAL_SCALE, DISABLED_MODULATE)

func _animate_button(btn: Button, target_scale: Vector2, target_modulate: Color) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", target_scale, ANIMATION_DURATION)
	tween.tween_property(btn, "modulate", target_modulate, ANIMATION_DURATION)

# ------------------------------------
# BUTTON PRESSED CALLBACKS
# ------------------------------------
func _on_start_pressed() -> void:
	_play_sfx(sfx_start)
	start_button.disabled = true

	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)
	await fade_scene.fade_out()
	GameData.enter_stage()
	GameData.hard_reset()
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_1.tscn")

func _on_stage_pressed() -> void:
	if stage_button.disabled:
		return
	_play_sfx(sfx_button)
	stage_level.visible = true
	is_panel_open = true

func _on_creadit_pressed() -> void:
	_play_sfx(sfx_button)
	creadit_panel.visible = true
	if video_stream_player:
		video_stream_player.play()
	is_panel_open = true

func _on_control_pressed() -> void:
	_play_sfx(sfx_button)
	control_panel.visible = true
	is_panel_open = true

func _on_quit_pressed() -> void:
	_play_sfx(sfx_button)
	get_tree().quit()

func _close_all_panels() -> void:
	control_panel.visible = false
	creadit_panel.visible = false
	stage_level.visible = false

	if video_stream_player and video_stream_player.is_playing():
		video_stream_player.stop()

	is_panel_open = false
	_play_sfx(sfx_button)
	_update_button_visuals()

func _play_sfx(sfx: AudioStreamPlayer2D) -> void:
	if sfx:
		sfx.play()
