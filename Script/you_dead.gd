extends CanvasLayer

signal respawn_pressed

@onready var root_control: Control = $Control
@onready var respawn: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Respawn
@onready var quit: Button = $"Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Main menu"
@onready var panel: Panel = $Control/Panel
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover

var buttons: Array[Button]
var selected_index := 0

func _ready() -> void:
	_init_ui()
	_connect_signals()

func show_you_dead() -> void:
	GameData.is_popup_open = true
	get_tree().paused = true
	root_control.show()
	
	await _animate_show()
	_enable_buttons()

func hide_you_dead() -> void:
	GameData.is_popup_open = false
	await _animate_hide()
	root_control.hide()

func _init_ui() -> void:
	root_control.hide()
	root_control.modulate.a = 0.0
	root_control.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	
	buttons = [respawn, quit]
	for btn in buttons:
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.8, 0.8)
	
	_update_button_focus()

func _connect_signals() -> void:
	respawn.pressed.connect(_on_respawn_pressed)
	quit.pressed.connect(_on_quit_pressed)

func _animate_show() -> void:
	_disable_buttons()
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(root_control, "modulate:a", 1.0, 0.5)
	tween.tween_property(root_control, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.4).set_delay(0.1)
	
	await get_tree().create_timer(0.3).timeout
	_animate_buttons_in()
	
	await tween.finished

func _animate_buttons_in() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		
		tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(i * 0.1)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.4).set_delay(i * 0.1)

func _animate_hide() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	for i in buttons.size():
		var btn := buttons[i]
		tween.tween_property(btn, "modulate:a", 0.0, 0.3)
		tween.tween_property(btn, "scale", Vector2(0.8, 0.8), 0.3)
	
	tween.tween_property(panel, "modulate:a", 0.0, 0.4).set_delay(0.1)
	tween.tween_property(root_control, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_property(root_control, "scale", Vector2(0.9, 0.9), 0.5).set_delay(0.2)
	
	await tween.finished

func _enable_buttons() -> void:
	for btn in buttons:
		btn.disabled = false
	_update_button_focus()

func _disable_buttons() -> void:
	for btn in buttons:
		btn.disabled = true

func _input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	
	if event.is_action_pressed("menu_left"):
		_move_selection(-1)
	elif event.is_action_pressed("menu_right"):
		_move_selection(1)
	elif event.is_action_pressed("ui_accept"):
		_press_selected_button()

func _move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, 0, buttons.size())
	sfx_hover.play()
	_animate_button_focus()

func _press_selected_button() -> void:
	var btn := buttons[selected_index]
	_animate_button_press(btn)
	await get_tree().create_timer(0.15).timeout
	btn.emit_signal("pressed")

func _update_button_focus() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0)
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)
			btn.scale = Vector2.ONE

func _animate_button_focus() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if i == selected_index:
			tween.tween_property(btn, "modulate", Color(0.7, 0.7, 0.7), 0.2)
			tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.2).set_trans(Tween.TRANS_BACK)
		else:
			tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5), 0.2)
			tween.tween_property(btn, "scale", Vector2.ONE, 0.2)

func _animate_button_press(btn: Button) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.08)

func _on_respawn_pressed() -> void:
	get_tree().paused = false
	await hide_you_dead()
	GameData.set_death(true)
	respawn_pressed.emit()

func _on_quit_pressed() -> void:
	var fade_node := get_tree().root.get_node_or_null("ScreenFade")
	if fade_node and fade_node.has_method("fade_out"):
		await fade_node.fade_out()
	
	GameData.reset()
	GameData.clear_data()
	GameData.clear_torch()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")
