extends CanvasLayer

@onready var next_stage_button: Button = $Control/Panel/VBoxContainer/HBoxContainer/Next_Stage_Button
@onready var main_menu_button: Button = $Control/Panel/VBoxContainer/HBoxContainer/Main_Menu_Button
@onready var panel: Panel = $Control/Panel
@onready var root_control: Control = $Control
@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var sfx_hover: AudioStreamPlayer2D = $SFX_Hover

var buttons: Array[Button] = []
var selected_index := 0
var is_paused := false

# Animation constants
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const PRESS_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_MODULATE: Color = Color(0.6, 0.6, 0.6)
const HOVER_MODULATE: Color = Color(1.0, 0.84, 0.0)  # Gold
const DISABLED_MODULATE: Color = Color(0.3, 0.3, 0.3, 0.5)
const ANIMATION_DURATION: float = 0.15

func _ready() -> void:
	_init_ui()
	_connect_signals()
	_set_process_mode_recursive(self)

func _set_process_mode_recursive(node: Node) -> void:
	# Set semua child nodes agar tetap process saat paused
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_process_mode_recursive(child)

func _unhandled_input(event: InputEvent) -> void:
	# Gunakan _unhandled_input agar lebih prioritas
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			hide_popup()
		else:
			show_popup()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	
	if event.is_action_pressed("menu_right"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_left"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_press_selected_button()
		get_viewport().set_input_as_handled()

func show_popup() -> void:
	print("Showing Pause Menu")
	is_paused = true
	root_control.show()
	get_tree().paused = true
	
	selected_index = 0
	_update_button_focus()

	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE

	_animate_buttons_in()

func hide_popup() -> void:
	print("Hiding Pause Menu")
	is_paused = false
	
	_animate_buttons_out()
	
	# Tunggu animasi selesai
	var timer = get_tree().create_timer(0.25, true, false, true)
	await timer.timeout
	
	root_control.hide()
	get_tree().paused = false

func _init_ui() -> void:
	buttons = [next_stage_button, main_menu_button]
	
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.8, 0.8)
	
	root_control.visible = false

func _connect_signals() -> void:
	for btn in buttons:
		btn.pressed.connect(_on_button_pressed)

func _animate_buttons_in() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

		tween.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(i * 0.1)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.3).set_delay(i * 0.1)

func _animate_buttons_out() -> void:
	for btn in buttons:
		var tween := create_tween().set_parallel(false)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		
		tween.tween_property(btn, "modulate:a", 0.0, 0.2)
		tween.tween_property(btn, "scale", Vector2(0.8, 0.8), 0.2)

func _move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, 0, buttons.size())
	sfx_hover.play()
	_update_button_focus()

func _update_button_focus() -> void:
	_animate_button_focus()

func _animate_button_focus() -> void:
	for i in buttons.size():
		var btn := buttons[i]
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		
		if i == selected_index:
			tween.tween_property(btn, "modulate", HOVER_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION)
		else:
			tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
			tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _press_selected_button() -> void:
	_animate_button_press(buttons[selected_index])
	var timer = get_tree().create_timer(ANIMATION_DURATION, true, false, true)
	await timer.timeout
	buttons[selected_index].emit_signal("pressed")

func _animate_button_press(btn: Button) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween.tween_property(btn, "scale", PRESS_SCALE, ANIMATION_DURATION * 0.5)
	tween.tween_property(btn, "scale", HOVER_SCALE, ANIMATION_DURATION * 0.5)

func _on_button_mouse_entered(btn: Button) -> void:
	if not is_paused:
		return
		
	var index = buttons.find(btn)
	if index != -1:
		selected_index = index
		sfx_hover.play()
		_update_button_focus()

func _on_button_mouse_exited(btn: Button) -> void:
	if not is_paused:
		return
		
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(btn, "modulate", NORMAL_MODULATE, ANIMATION_DURATION)
	tween.tween_property(btn, "scale", NORMAL_SCALE, ANIMATION_DURATION)

func _on_button_pressed() -> void:
	sfx_button.play()
	
	if buttons[selected_index] == next_stage_button:
		await hide_popup()
		_change_to_next_stage()
	elif buttons[selected_index] == main_menu_button:
		await hide_popup()
		_change_to_main_menu()

func _change_to_next_stage() -> void:
	get_tree().paused = false
	GameData.is_scene_changing = true
	GameData.reset()
	GameData.clear_data()
	GameData.clear_torch()
	GameData.set_finish_stage1()
	GameData.is_popup_open = false
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_2.tscn")

func _change_to_main_menu() -> void:
	get_tree().paused = false
	GameData.is_scene_changing = true
	GameData.reset()
	GameData.clear_data()
	GameData.clear_torch()
	GameData.set_finish_stage1()
	get_tree().change_scene_to_file("res://Scenes/FIX/MainMenu.tscn")

# Public methods untuk kontrol dari luar
func force_show_popup() -> void:
	show_popup()

func force_hide_popup() -> void:
	hide_popup()

func get_pause_state() -> bool:
	return is_paused
