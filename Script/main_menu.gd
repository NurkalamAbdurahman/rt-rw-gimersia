extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Quit
@onready var control_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Control
@onready var control_panel: Control = $Control
@onready var creadit_button: Button = $MarginContainer2/Creadit
@onready var creadit_panel: Control = $Creadit


var selected_index: int = 0
var buttons: Array[Button] = []




func _ready() -> void:
	# Semua tombol yang bisa dinavigasi dengan arrow keys
	buttons = [start_button,creadit_button, quit_button, control_button]

	# Disable auto focus & mouse
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect event
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	control_button.pressed.connect(_on_control_pressed)
	creadit_button.pressed.connect(_on_creadit_pressed)

	# Indikasi fokus awal
	_update_button_focus()

	set_process_input(true)



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_move_selection(1)

	elif event.is_action_pressed("ui_down"):
		_move_selection(-1)

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			_move_selection(1)
			
		elif event.keycode == KEY_S:
			_move_selection(-1)
			
		elif event.is_action_pressed("ui_accept"):
			buttons[selected_index].emit_signal("pressed")




func _move_selection(direction: int) -> void:
	selected_index += direction

	# Looping
	if selected_index < 0:
		selected_index = buttons.size() - 1
	elif selected_index >= buttons.size():
		selected_index = 0

	_update_button_focus()



func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]

		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0)   # emas
			btn.scale = Vector2(1.12, 1.12)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)     # abu-abu
			btn.scale = Vector2(1, 1)



func _on_start_pressed() -> void:
	print("Start pressed")
	start_button.disabled = true

	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)
	await fade_scene.fade_out()
	get_tree().change_scene_to_file("res://Scenes/FIX/STAGE_1.tscn")



func _on_quit_pressed() -> void:
	print("Quit pressed")
	get_tree().quit()



func _on_control_pressed() -> void:
	print("Control Menu Opened")
	control_panel.visible = true

func _on_creadit_pressed() -> void:
	print("Creadit Menu Opened")
	creadit_panel.visible = true
