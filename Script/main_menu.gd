extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Start
@onready var quit_button: Button = $MarginContainer/VBoxContainer/VBoxContainer/Quit

var buttons: Array[Button] = []
var selected_index: int = 0

func _ready() -> void:
	# Simpan tombol ke array
	buttons = [start_button, quit_button]

	# Hubungkan sinyal tombol
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Fokus awal ke tombol pertama
	_update_button_focus()

	# Pastikan input UI aktif
	set_process_input(true)


func _input(event: InputEvent) -> void:
	# Navigasi keyboard
	if event.is_action_pressed("ui_down"):
		selected_index = (selected_index + 1) % buttons.size()
		_update_button_focus()

	elif event.is_action_pressed("ui_up"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		_update_button_focus()

	elif event.is_action_pressed("ui_accept"):
		buttons[selected_index].emit_signal("pressed")


func _update_button_focus() -> void:
	for i in range(buttons.size()):
		if i == selected_index:
			buttons[i].grab_focus()
	# Tidak perlu manual hilangkan fokus; Godot otomatis handle


func _on_start_pressed() -> void:
	start_button.disabled = true

	# Tambahkan fade transition
	var fade_scene = preload("res://Scenes/ui/fade_transitions.tscn").instantiate()
	get_tree().root.add_child(fade_scene)

	await fade_scene.fade_out()  # pastikan fade_out() adalah fungsi async di fade_scene

	get_tree().change_scene_to_file("res://Scenes/Stage_Nun.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
