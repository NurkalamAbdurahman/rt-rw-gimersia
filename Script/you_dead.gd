extends CanvasLayer

@onready var root_control: Control = $Control
@onready var respawn: Button = $Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Respawn
@onready var quit: Button = $"Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/Main menu"
@onready var panel: Panel = $Control/Panel

signal respawn_pressed

var tween: Tween
var buttons: Array[Button]
var selected_index: int = 0

func _ready() -> void:
	root_control.hide()
	root_control.modulate.a = 0.0
	root_control.scale = Vector2(0.8, 0.8)
	
	respawn.pressed.connect(_on_respawn_pressed)
	quit.pressed.connect(_on_quit_pressed)

	buttons = [respawn, quit]
	_update_button_focus()

func show_you_dead():
	root_control.show()

	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()

	root_control.modulate.a = 0.0
	root_control.scale = Vector2(0.8, 0.8)
	
	tween.tween_property(root_control, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root_control, "scale", Vector2(1, 1), 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	respawn.disabled = true
	quit.disabled = true
	await get_tree().create_timer(0.6).timeout
	respawn.disabled = false
	quit.disabled = false
	_update_button_focus()

func hide_you_dead():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	
	tween.tween_property(root_control, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(root_control, "scale", Vector2(0.9, 0.9), 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	await tween.finished
	root_control.hide()

func _on_respawn_pressed():
	await hide_you_dead()
	emit_signal("respawn_pressed")

func _on_quit_pressed():
	var fade_node = get_tree().root.get_node_or_null("ScreenFade")
	if fade_node and fade_node.has_method("fade_out"):
		await fade_node.fade_out()
	get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	
	if event.is_action_pressed("menu_left"):
		_move_selection(-1)

	elif event.is_action_pressed("menu_right"):
		_move_selection(1)

	elif event.is_action_pressed("ui_accept"):
		buttons[selected_index].emit_signal("pressed")

func _move_selection(dir: int) -> void:
	selected_index = wrapi(selected_index + dir, 0, buttons.size())
	_update_button_focus()

func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0) # Emas
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7) # Abu-abu
			btn.scale = Vector2(1.0, 1.0)
