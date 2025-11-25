extends Control

@export var pause_key: String = "esc"

@onready var panel: Panel = $Panel
@onready var texture_rect: Sprite2D = $Panel/UiPaused
@onready var text_edit: Label = $Panel/Label

@onready var resume_button: Button = $Panel/VBoxContainer/resume
@onready var controls_button: Button = $Panel/VBoxContainer/controls
@onready var quit_button: Button = $Panel/VBoxContainer/quit

@onready var confirm_panel: Panel = $Confirm
@onready var yes_button: Button = $Confirm/VBoxContainer/HBoxContainer/ya
@onready var no_button: Button = $Confirm/VBoxContainer/HBoxContainer/tidak

@onready var control_menu: Panel = $Control

@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover

var buttons: Array[Button] = []
var selected_index := 0

var confirm_buttons: Array[Button] = []
var confirm_index := 0

func _ready() -> void:
	_init_ui()
	_connect_signals()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(pause_key) and not GameData.is_popup_open:
		_handle_escape()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if confirm_panel.visible:
		_handle_confirm_input(event)
	elif panel.visible:
		_handle_pause_input(event)

func _init_ui() -> void:
	buttons = [resume_button, controls_button, quit_button]
	confirm_buttons = [yes_button, no_button]
	
	for btn in buttons + confirm_buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	visible = false
	confirm_panel.visible = false
	control_menu.visible = false

func _connect_signals() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)

func _handle_escape() -> void:
	if control_menu.visible:
		_close_controls()
		return
	
	if confirm_panel.visible:
		_close_confirm()
		return
	
	_toggle_pause()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	
	if get_tree().paused:
		_show_pause()
	else:
		_hide_pause()

func _show_pause() -> void:
	visible = true
	panel.visible = true
	text_edit.visible = true
	texture_rect.visible = true
	
	selected_index = 0
	_update_focus()

func _hide_pause() -> void:
	visible = false

func _show_confirm() -> void:
	panel.visible = false
	text_edit.visible = false
	texture_rect.visible = false
	confirm_panel.visible = true
	
	confirm_index = 0
	_update_confirm_focus()

func _close_confirm() -> void:
	confirm_panel.visible = false
	panel.visible = true
	text_edit.visible = true
	texture_rect.visible = true

func _show_controls() -> void:
	panel.visible = false
	text_edit.visible = false
	texture_rect.visible = false
	control_menu.visible = true

func _close_controls() -> void:
	control_menu.visible = false
	panel.visible = true
	text_edit.visible = true
	texture_rect.visible = true

func _handle_pause_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_up"):
		_move_selection(-1)
	elif event.is_action_pressed("menu_down"):
		_move_selection(1)
	elif event.is_action_pressed("resume"):
		_press_selected_button(buttons[selected_index])

func _handle_confirm_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_left"):
		_move_confirm(-1)
	elif event.is_action_pressed("menu_right"):
		_move_confirm(1)
	elif event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		_move_confirm(1)
	elif event.is_action_pressed("resume"):
		_press_selected_button(confirm_buttons[confirm_index])

func _move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, 0, buttons.size())
	sfx_hover.play()
	_animate_button_focus(buttons, selected_index)

func _move_confirm(direction: int) -> void:
	confirm_index = wrapi(confirm_index + direction, 0, confirm_buttons.size())
	sfx_hover.play()
	_animate_button_focus(confirm_buttons, confirm_index)

func _update_focus() -> void:
	_animate_button_focus(buttons, selected_index)

func _update_confirm_focus() -> void:
	_animate_button_focus(confirm_buttons, confirm_index)

func _animate_button_focus(target_buttons: Array[Button], focus_index: int) -> void:
	for i in target_buttons.size():
		var btn := target_buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if i == focus_index:
			tween.tween_property(btn, "modulate", Color(1.0, 0.84, 0.0), 0.2)
			tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.2).set_trans(Tween.TRANS_BACK)
		else:
			tween.tween_property(btn, "modulate", Color.WHITE, 0.2)
			tween.tween_property(btn, "scale", Vector2.ONE, 0.2)

func _press_selected_button(btn: Button) -> void:
	_animate_button_press(btn)
	await get_tree().create_timer(0.15).timeout
	btn.emit_signal("pressed")

func _animate_button_press(btn: Button) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.08)

func _on_resume_pressed() -> void:
	sfx_button.play()
	get_tree().paused = false
	_hide_pause()

func _on_controls_pressed() -> void:
	sfx_button.play()
	_show_controls()

func _on_exit_control_pressed() -> void:
	sfx_button.play()
	_close_controls()

func _on_quit_pressed() -> void:
	sfx_button.play()
	_show_confirm()

func _on_yes_pressed() -> void:
	sfx_button.play()
	get_tree().paused = false
	GameData.reset()
	GameData.set_death(false)
	GameData.clear_data()
	GameData.clear_torch()
	get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")

func _on_no_pressed() -> void:
	sfx_button.play()
	_close_confirm()
