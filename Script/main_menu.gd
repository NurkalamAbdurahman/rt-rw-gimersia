extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Quit

var selected_index: int = 0 # 0 = start, 1 = quit
var buttons: Array[Button] = []

func _ready() -> void:
	buttons = [start_button, quit_button]

	# Hilangkan auto-focus dan mouse influence
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Hubungkan event tombol
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Set fokus awal
	_update_button_focus()
	set_process_input(true)


func _input(event: InputEvent) -> void:
	# Tekan panah atas
	if event.is_action_pressed("ui_up"):
		selected_index = 0
		_update_button_focus()

	# Tekan panah bawah
	elif event.is_action_pressed("ui_down"):
		selected_index = 1
		_update_button_focus()

	# Tekan enter / accept
	elif event.is_action_pressed("ui_accept"):
		if selected_index == 0:
			_on_start_pressed()
		elif selected_index == 1:
			_on_quit_pressed()


func _update_button_focus() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]

		# Fokus emas untuk tombol aktif
		if i == selected_index:
			btn.modulate = Color(1.0, 0.84, 0.0)  # emas
			btn.scale = Vector2(1.1, 1.1)          # sedikit membesar
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)    # non aktif (abu)
			btn.scale = Vector2(1, 1)


func _on_start_pressed() -> void:
	print("Start pressed")
	start_button.disabled = true

	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)
	await fade_scene.fade_out()
	get_tree().change_scene_to_file("res://Scenes/Stage_Nun.tscn")


func _on_quit_pressed() -> void:
	print("Quit pressed")
	get_tree().quit()
