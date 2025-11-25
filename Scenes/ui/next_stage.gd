extends CanvasLayer

@onready var next_stage_button: Button = $Control/Panel/VBoxContainer/VBoxContainer/Next_Stage_Button
@onready var main_menu_button: Button = $Control/Panel/VBoxContainer/VBoxContainer/Main_Menu_Button
@onready var panel: Panel = $Control/Panel
@onready var root_control: Control = $Control
@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover

var buttons: Array[Button] = []
var selected_index := 0

func _ready() -> void:
	_init_ui()
	_connect_signals()

func _input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	
	if event.is_action_pressed("menu_up"):
		_move_selection(1)
	elif event.is_action_pressed("menu_down"):
		_move_selection(-1)
	elif event.is_action_pressed("ui_accept"):
		_press_selected_button()

func show_popup() -> void:
	print("pause ini!!!")
	get_tree().paused = true
	root_control.show()
	
	selected_index = 0
	_update_button_focus()
	
	await _animate_show()

func hide_popup() -> void:
	print("lewat bang")
	await _animate_hide()
	root_control.hide()
	get_tree().paused = false

func _init_ui() -> void:
	buttons = [next_stage_button, main_menu_button]
	
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.8, 0.8)
	
	root_control.visible = false
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)

func _connect_signals() -> void:
	for btn in buttons:
		btn.pressed.connect(_on_button_pressed)

func _animate_show() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	
	await get_tree().create_timer(0.3).timeout
	_animate_buttons_in()
	
	await tween.finished

func _animate_hide() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	for btn in buttons:
		tween.tween_property(btn, "modulate:a", 0.0, 0.3)
		tween.tween_property(btn, "scale", Vector2(0.8, 0.8), 0.3)
	
	tween.tween_property(panel, "modulate:a", 0.0, 0.4).set_delay(0.2)
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.4).set_delay(0.2)
	
	await tween.finished

func _animate_buttons_in() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		
		tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(i * 0.1)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.4).set_delay(i * 0.1)

func _move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, 0, buttons.size())
	sfx_hover.play()
	_animate_button_focus()

func _update_button_focus() -> void:
	_animate_button_focus()

func _animate_button_focus() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if i == selected_index:
			tween.tween_property(btn, "theme_override_colors/font_color", Color(1.0, 0.84, 0.0), 0.2)
			tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.2).set_trans(Tween.TRANS_BACK)
		else:
			tween.tween_property(btn, "theme_override_colors/font_color", Color(0.7, 0.7, 0.7), 0.2)
			tween.tween_property(btn, "scale", Vector2.ONE, 0.2)

func _press_selected_button() -> void:
	_animate_button_press(buttons[selected_index])
	await get_tree().create_timer(0.15).timeout
	buttons[selected_index].emit_signal("pressed")

func _animate_button_press(btn: Button) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.08)

func _on_button_pressed() -> void:
	sfx_button.play()
	
	if buttons[selected_index] == next_stage_button:
		await hide_popup()
		_change_to_next_stage()
	elif buttons[selected_index] == main_menu_button:
		await hide_popup()
		_change_to_main_menu()

func _change_to_next_stage() -> void:
	GameData.is_scene_changing = true
	GameData.reset()
	GameData.clear_data()
	GameData.clear_torch()
	GameData.set_finish_stage1()
	GameData.is_popup_open = false
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_2.tscn")

func _change_to_main_menu() -> void:
	GameData.is_scene_changing = true
	GameData.reset()
	GameData.clear_data()
	GameData.clear_torch()
	GameData.set_finish_stage1()
	get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")
